// keypad.m —— 注入到 WMMT 可执行文件的按键布局补丁（dylib）
//
// 两条链路：
//  大小：主程序里 _KEY_K 是个全局 float（初值 1.0），hud_touch 判命中、hud_draw 画按键都读它，
//        运行时改这个变量，按键整体缩放，命中区域同步跟着变。
//  位置：可执行文件被 patch_pos.py 改过一处 —— 按键矩阵上传前跳进代码洞，
//        把 m[12]/m[13] 加上 (dx, dy)（NDC 单位）。触摸这边用 swizzle
//        -[UITouch locationInView:] 把坐标反向平移同样的点数，两边严丝合缝。
//
// 交互：三指轻点屏幕 -> 面板；大小 +/-，位置四向微调，实时生效，
//       自动写回 Documents/keylayout.txt。

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach/mach.h>

#define KEYK_OFF   0x556040ULL  /* _KEY_K           */
#define POSDAT_OFF 0x672D40ULL  /* dx_ndc, dy_ndc   */
#define SITE_OFF   0x37214ULL   /* 被改成 b 代码洞的那条指令 */
#define SITE_B_PATCH 0x17FF2F7BUL

static float *g_keyk = NULL;
static float *g_pos = NULL;   /* [0]=dx_ndc [1]=dy_ndc */
static BOOL g_patched = NO;

static float g_k = 1.0f, g_dx = 0.0f, g_dy = 0.0f;
static UIView *g_panel = nil;
static UILabel *g_val = NULL, *g_posv = NULL;

#pragma mark - 存档

static NSString *cfg_path(void) {
  NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  if (dirs.count == 0) return nil;
  return [dirs[0] stringByAppendingPathComponent:@"keylayout.txt"];
}

static void cfg_load(void) {
  NSString *p = cfg_path();
  if (!p) return;
  NSString *s = [NSString stringWithContentsOfFile:p encoding:NSUTF8StringEncoding error:NULL];
  if (!s) return;
  for (NSString *line in [s componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
    if ([line hasPrefix:@"k="]) {
      float v = [[line substringFromIndex:2] floatValue];
      if (v >= 0.6f && v <= 1.6f) g_k = v;
    } else if ([line hasPrefix:@"dx="]) {
      g_dx = [[line substringFromIndex:3] floatValue];
    } else if ([line hasPrefix:@"dy="]) {
      g_dy = [[line substringFromIndex:3] floatValue];
    }
  }
  if (g_dx < -0.5f) g_dx = -0.5f;
  if (g_dx > 0.5f) g_dx = 0.5f;
  if (g_dy < -0.5f) g_dy = -0.5f;
  if (g_dy > 0.5f) g_dy = 0.5f;
}

static void cfg_save(void) {
  NSString *p = cfg_path();
  if (!p) return;
  NSString *s = [NSString stringWithFormat:@"k=%.3f\ndx=%.3f\ndy=%.3f\n", g_k, g_dx, g_dy];
  [s writeToFile:p atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

#pragma mark - 生效

static void apply_all(void) {
  if (g_keyk) *g_keyk = g_k;
  if (g_pos && g_patched) {
    g_pos[0] = g_dx;
    g_pos[1] = g_dy;
  }
  if (g_val) g_val.text = [NSString stringWithFormat:@"%.2f", g_k];
  if (g_posv) g_posv.text = [NSString stringWithFormat:@"%+.2f %+.2f", g_dx, g_dy];
}

/* 游戏在窗口尺寸变化时会用 hud_wide 把 KEY_K 写回 1.0，这里每半秒守一次 */
static void guard_timer(void) {
  dispatch_source_t t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                               dispatch_get_main_queue());
  dispatch_source_set_timer(t, dispatch_time(DISPATCH_TIME_NOW, 0),
                            500ull * NSEC_PER_MSEC, 50ull * NSEC_PER_MSEC);
  dispatch_source_set_event_handler(t, ^{
    if (g_keyk && *g_keyk != g_k) *g_keyk = g_k;
    if (g_pos && g_patched && (g_pos[0] != g_dx || g_pos[1] != g_dy)) {
      g_pos[0] = g_dx;
      g_pos[1] = g_dy;
    }
  });
  dispatch_resume(t);
}

#pragma mark - 触摸坐标同步平移

static IMP g_orig_loc = NULL;

static BOOL fullscreen_view(UIView *v) {
  if (!v) return NO;
  UIWindow *w = v.window ?: [UIApplication sharedApplication].windows.firstObject;
  if (!w) return NO;
  CGSize a = v.bounds.size, b = w.bounds.size;
  return a.width >= b.width * 0.9f && a.height >= b.height * 0.9f;
}

static CGPoint kp_locationInView(id self, SEL _cmd, UIView *view) {
  CGPoint p = ((CGPoint (*)(id, SEL, UIView *))g_orig_loc)(self, _cmd, view);
  if ((g_dx != 0 || g_dy != 0) && fullscreen_view(view)) {
    CGSize s = view.bounds.size;
    p.x -= g_dx * (float)s.width * 0.5f;   /* dx>0 键右移 -> 触点左移回来 */
    p.y += g_dy * (float)s.height * 0.5f;  /* dy>0 键上移 -> 触点下移回来 */
  }
  return p;
}

static void install_touch_shift(void) {
  Method m = class_getInstanceMethod([UITouch class], @selector(locationInView:));
  if (!m) return;
  g_orig_loc = method_getImplementation(m);
  method_setImplementation(m, (IMP)kp_locationInView);
}

#pragma mark - 面板

static UIButton *mk_button(NSString *title, CGRect r, id target, SEL sel) {
  UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
  b.frame = r;
  [b setTitle:title forState:UIControlStateNormal];
  [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  b.titleLabel.font = [UIFont boldSystemFontOfSize:21];
  b.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.16];
  b.layer.cornerRadius = 10;
  [b addTarget:target action:sel forControlEvents:UIControlEventTouchUpInside];
  return b;
}

@interface KeyPadPanel : NSObject
+ (void)toggle;
@end

@implementation KeyPadPanel

+ (void)size_step:(UIButton *)b {
  g_k += (b.tag == 1 ? 0.05f : -0.05f);
  if (g_k < 0.6f) g_k = 0.6f;
  if (g_k > 1.6f) g_k = 1.6f;
  apply_all();
  cfg_save();
}

+ (void)pos_step:(UIButton *)b {
  const float st = 0.02f;
  switch (b.tag) {
    case 0: g_dx += st; break;   /* → */
    case 1: g_dx -= st; break;   /* ← */
    case 2: g_dy += st; break;   /* ↑ */
    default: g_dy -= st; break;  /* ↓ */
  }
  if (g_dx < -0.5f) g_dx = -0.5f;
  if (g_dx > 0.5f) g_dx = 0.5f;
  if (g_dy < -0.5f) g_dy = -0.5f;
  if (g_dy > 0.5f) g_dy = 0.5f;
  apply_all();
  cfg_save();
}

+ (void)pos_reset:(UIButton *)b {
  g_dx = g_dy = 0;
  apply_all();
  cfg_save();
}

+ (void)close:(UIButton *)b {
  [UIView animateWithDuration:0.18 animations:^{ g_panel.alpha = 0; }
                   completion:^(BOOL f) { g_panel.hidden = YES; g_panel.alpha = 1; }];
}

+ (void)toggle {
  if (g_panel) {
    g_panel.hidden = !g_panel.hidden;
    if (!g_panel.hidden) apply_all();
    return;
  }
  UIWindow *w = [UIApplication sharedApplication].windows.firstObject;
  if (!w) return;

  CGRect f = w.bounds;
  CGFloat pw = 320, ph = 248;
  g_panel = [[UIView alloc] initWithFrame:CGRectMake((f.size.width - pw) / 2,
                                                    (f.size.height - ph) / 2, pw, ph)];
  g_panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.88];
  g_panel.layer.cornerRadius = 18;
  g_panel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                             UIViewAutoresizingFlexibleRightMargin |
                             UIViewAutoresizingFlexibleTopMargin |
                             UIViewAutoresizingFlexibleBottomMargin;

  UILabel *t1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, pw, 22)];
  t1.text = @"按键大小";
  t1.textColor = [UIColor colorWithWhite:0.75 alpha:1];
  t1.textAlignment = NSTextAlignmentCenter;
  t1.font = [UIFont boldSystemFontOfSize:15];
  [g_panel addSubview:t1];

  UIButton *minus = mk_button(@"−", CGRectMake(24, 34, 64, 46), [KeyPadPanel class], @selector(size_step:));
  minus.tag = 0;
  UIButton *plus = mk_button(@"+", CGRectMake(pw - 88, 34, 64, 46), [KeyPadPanel class], @selector(size_step:));
  plus.tag = 1;
  g_val = [[UILabel alloc] initWithFrame:CGRectMake(92, 34, pw - 184, 46)];
  g_val.textColor = [UIColor colorWithRed:1.0 green:0.62 blue:0.1 alpha:1];
  g_val.textAlignment = NSTextAlignmentCenter;
  g_val.font = [UIFont monospacedDigitSystemFontOfSize:24 weight:UIFontWeightBold];

  UILabel *t2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 88, pw, 22)];
  t2.text = @"按键位置";
  t2.textColor = [UIColor colorWithWhite:0.75 alpha:1];
  t2.textAlignment = NSTextAlignmentCenter;
  t2.font = [UIFont boldSystemFontOfSize:15];
  [g_panel addSubview:t2];

  UIButton *up = mk_button(@"↑", CGRectMake(pw / 2 - 32, 112, 64, 42), [KeyPadPanel class], @selector(pos_step:));
  up.tag = 2;
  UIButton *down = mk_button(@"↓", CGRectMake(pw / 2 - 32, 158, 64, 42), [KeyPadPanel class], @selector(pos_step:));
  down.tag = 3;
  UIButton *left = mk_button(@"←", CGRectMake(pw / 2 - 106, 135, 64, 42), [KeyPadPanel class], @selector(pos_step:));
  left.tag = 1;
  UIButton *right = mk_button(@"→", CGRectMake(pw / 2 + 42, 135, 64, 42), [KeyPadPanel class], @selector(pos_step:));
  right.tag = 0;

  g_posv = [[UILabel alloc] initWithFrame:CGRectMake(14, 204, 120, 24)];
  g_posv.textColor = [UIColor colorWithWhite:0.8 alpha:1];
  g_posv.textAlignment = NSTextAlignmentLeft;
  g_posv.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];

  UIButton *zero = mk_button(@"归零", CGRectMake(146, 200, 76, 34), [KeyPadPanel class], @selector(pos_reset:));
  zero.titleLabel.font = [UIFont boldSystemFontOfSize:15];
  UIButton *done = mk_button(@"完成", CGRectMake(230, 200, 76, 34), [KeyPadPanel class], @selector(close:));
  done.titleLabel.font = [UIFont boldSystemFontOfSize:15];

  for (UIView *v in @[ minus, plus, g_val, t2, up, down, left, right, g_posv, zero, done ])
    [g_panel addSubview:v];
  [w addSubview:g_panel];
  apply_all();
}

@end

#pragma mark - 三指轻点唤出

@interface KeyPadGesture : NSObject
@end

@implementation KeyPadGesture
- (void)tapped:(UIGestureRecognizer *)g {
  if (g.state == UIGestureRecognizerStateBegan || [g isKindOfClass:[UITapGestureRecognizer class]])
    [KeyPadPanel toggle];
}
@end

static KeyPadGesture *g_gest = nil;
static __weak UIWindow *g_win = nil;

static void install_gesture(void) {
  UIWindow *w = [UIApplication sharedApplication].windows.firstObject;
  if (!w) return;
  if (g_gest && w == g_win) return;
  g_win = w;
  if (!g_gest) g_gest = [KeyPadGesture new];

  UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc] initWithTarget:g_gest
                                                                     action:@selector(tapped:)];
  t.numberOfTouchesRequired = 3;
  t.cancelsTouchesInView = NO;
  [w addGestureRecognizer:t];

  UILongPressGestureRecognizer *lp =
      [[UILongPressGestureRecognizer alloc] initWithTarget:g_gest action:@selector(tapped:)];
  lp.numberOfTouchesRequired = 3;
  lp.minimumPressDuration = 0.9;
  lp.cancelsTouchesInView = NO;
  [w addGestureRecognizer:lp];
}

#pragma mark - 定位主程序并启动

static void *main_image_base(void) {
  uint32_t n = _dyld_image_count();
  for (uint32_t i = 0; i < n; ++i) {
    const struct mach_header *h = _dyld_get_image_header(i);
    if (h && h->filetype == MH_EXECUTE)
      return (void *)((uintptr_t)h + (uintptr_t)_dyld_get_image_vmaddr_slide(i));
  }
  return NULL;
}

static void boot(void);

static void boot(void) {
  void *base = main_image_base();
  if (base && !g_keyk) {
    g_keyk = (float *)((uintptr_t)base + KEYK_OFF);
    uint32_t site = *(uint32_t *)((uintptr_t)base + SITE_OFF);
    g_patched = (site == SITE_B_PATCH);
    if (g_patched) g_pos = (float *)((uintptr_t)base + POSDAT_OFF);
    cfg_load();
    apply_all();
    guard_timer();
    install_touch_shift();
    NSLog(@"[keypad] base=%p k=%.2f dx=%.3f dy=%.3f patched=%d",
          base, g_k, g_dx, g_dy, (int)g_patched);
  }
  install_gesture();
  if (!g_gest || !g_win) {
    static int tries = 0;
    if (++tries < 80)
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500ull * NSEC_PER_MSEC),
                     dispatch_get_main_queue(), ^{ boot(); });
  }
}

__attribute__((constructor)) static void keypad_init(void) {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1500ull * NSEC_PER_MSEC),
                 dispatch_get_main_queue(), ^{ boot(); });
}
