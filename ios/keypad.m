// keypad.m —— 注入到 WMMT 可执行文件的布局补丁（dylib）
//
// 两个全局，运行时直接改，绘制和触摸判定读的是同一份数据，所以永远同步：
//   _KEY_K  @0x556040  按键缩放，1.0 为原大
//   _EDGE   @0x584818  画布左右扩展量（hud_wide 写一次）
//
// EDGE 决定 HUD 的水平铺开程度：按键坐标是固定的（16 / 812 这类常量），
// 投影把画布 [-EDGE, 1024+EDGE] 铺满整屏。EDGE 越大，按键越往中间收。
// 全屏后 EDGE 被算得很大，按键被顶到屏幕边缘，这版把它固定在指定值，
// 让按键回到接近 4:3 letterbox 时的位置。
//
// 交互：三指轻点（或三指长按 0.9s）唤出面板，调大小 / 内收，实时生效，
//       自动写回 Documents/keylayout.txt。

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach/mach.h>

#define KEYK_OFF 0x556040ULL
#define EDGE_OFF 0x584818ULL

static float *g_keyk = NULL;
static float *g_edgep = NULL;

static float g_k = 1.0f;
static float g_edge = 480.0f;    /* 目标 EDGE（画布像素） */
static float g_raw = 0.0f;       /* 游戏自己算出来的 EDGE */
static float g_e0 = 0.0f;        /* 启动时的原始 EDGE（触摸换算基准） */
static BOOL g_e0_ok = NO;
static UIView *g_panel = nil;
static UILabel *g_val = NULL, *g_edgev = NULL, *g_debug = NULL;

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
    } else if ([line hasPrefix:@"e="]) {
      float v = [[line substringFromIndex:2] floatValue];
      if (v >= 0.0f && v <= 1000.0f) g_edge = v;
    }
  }
}

static void cfg_save(void) {
  NSString *p = cfg_path();
  if (!p) return;
  NSString *s = [NSString stringWithFormat:@"k=%.3f\ne=%.1f\n", g_k, g_edge];
  [s writeToFile:p atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

#pragma mark - 生效

static void apply_all(void) {
  if (g_keyk) *g_keyk = g_k;
  if (g_edgep) *g_edgep = g_edge;
  if (g_val) g_val.text = [NSString stringWithFormat:@"%.2f", g_k];
  if (g_edgev) g_edgev.text = [NSString stringWithFormat:@"%.0f", g_edge];
  if (g_debug)
    g_debug.text = [NSString stringWithFormat:@"原 EDGE %.0f   实际 %.0f", g_raw, g_edge];
}

/* 游戏在窗口尺寸变化时会重算 KEY_K / EDGE，这里持续守护 */
static void guard_timer(void) {
  dispatch_source_t t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                               dispatch_get_main_queue());
  dispatch_source_set_timer(t, dispatch_time(DISPATCH_TIME_NOW, 0),
                            400ull * NSEC_PER_MSEC, 50ull * NSEC_PER_MSEC);
  dispatch_source_set_event_handler(t, ^{
    if (g_keyk && *g_keyk != g_k) *g_keyk = g_k;
    if (g_edgep && *g_edgep != g_edge) {
      if (fabsf(*g_edgep - g_edge) > 0.5f) {
        g_raw = *g_edgep;
        g_e0 = g_raw; g_e0_ok = YES;   /* 游戏重算过布局，更新触摸换算基准 */
      }
      *g_edgep = g_edge;
      if (g_debug)
        g_debug.text = [NSString stringWithFormat:@"原 EDGE %.0f   实际 %.0f", g_e0, g_edge];
    }
  });
  dispatch_resume(t);
}

#pragma mark - 触摸坐标补偿
//
// 游戏在 GLView 里用 self.touch_edge（画布扩展量）把屏幕点换算成画布坐标：
//   world = px * k - touch_edge
// 我们把全局 EDGE 改成 g_edge 后，绘制按新的 [-E1, 1024+E1] 铺开，
// 但触摸仍按旧的 E0 换算，两者会越差越远。屏幕点按比例缩放即可精确对齐：
//   S' = S * (1024 + 2*E1) / (1024 + 2*E0)
// 只对 GLView 生效，菜单按钮走 UIKit，不受影响。

static IMP g_orig_loc = NULL;

static CGPoint kp_locationInView(id self, SEL _cmd, UIView *view) {
  CGPoint p = ((CGPoint (*)(id, SEL, UIView *))g_orig_loc)(self, _cmd, view);
  if (view && g_e0_ok && fabsf(g_edge - g_e0) > 1.0f) {
    static Class glv = Nil;
    if (!glv) glv = NSClassFromString(@"GLView");
    if (glv && [view isKindOfClass:glv]) {
      float f = (1024.0f + 2.0f * g_edge) / (1024.0f + 2.0f * g_e0);
      p.x *= f;   /* 只有水平方向被拉伸，纵向 0..768 不变 */
    }
  }
  return p;
}

static void install_touch_fix(void) {
  Method m = class_getInstanceMethod([UITouch class], @selector(locationInView:));
  if (!m || g_orig_loc) return;
  g_orig_loc = method_getImplementation(m);
  method_setImplementation(m, (IMP)kp_locationInView);
}

#pragma mark - 面板

static UIButton *mk_button(NSString *title, CGRect r, id target, SEL sel) {
  UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
  b.frame = r;
  [b setTitle:title forState:UIControlStateNormal];
  [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  b.titleLabel.font = [UIFont boldSystemFontOfSize:24];
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

+ (void)edge_step:(UIButton *)b {
  g_edge += (b.tag == 1 ? 40.0f : -40.0f);
  if (g_edge < 0.0f) g_edge = 0.0f;
  if (g_edge > 900.0f) g_edge = 900.0f;
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
  CGFloat pw = 340, ph = 236;
  g_panel = [[UIView alloc] initWithFrame:CGRectMake((f.size.width - pw) / 2,
                                                    (f.size.height - ph) / 2, pw, ph)];
  g_panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.9];
  g_panel.layer.cornerRadius = 18;
  g_panel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                             UIViewAutoresizingFlexibleRightMargin |
                             UIViewAutoresizingFlexibleTopMargin |
                             UIViewAutoresizingFlexibleBottomMargin;

  UILabel *t1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, pw, 20)];
  t1.text = @"按键大小";
  t1.textColor = [UIColor colorWithWhite:0.75 alpha:1];
  t1.textAlignment = NSTextAlignmentCenter;
  t1.font = [UIFont boldSystemFontOfSize:15];
  [g_panel addSubview:t1];

  UIButton *minus = mk_button(@"−", CGRectMake(24, 30, 68, 50), [KeyPadPanel class], @selector(size_step:));
  minus.tag = 0;
  UIButton *plus = mk_button(@"+", CGRectMake(pw - 92, 30, 68, 50), [KeyPadPanel class], @selector(size_step:));
  plus.tag = 1;
  g_val = [[UILabel alloc] initWithFrame:CGRectMake(96, 30, pw - 192, 50)];
  g_val.textColor = [UIColor colorWithRed:1.0 green:0.62 blue:0.1 alpha:1];
  g_val.textAlignment = NSTextAlignmentCenter;
  g_val.font = [UIFont monospacedDigitSystemFontOfSize:26 weight:UIFontWeightBold];

  UILabel *t2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 90, pw, 20)];
  t2.text = @"按键内收（越大越靠中间）";
  t2.textColor = [UIColor colorWithWhite:0.75 alpha:1];
  t2.textAlignment = NSTextAlignmentCenter;
  t2.font = [UIFont boldSystemFontOfSize:15];
  [g_panel addSubview:t2];

  UIButton *eminus = mk_button(@"−", CGRectMake(24, 112, 68, 50), [KeyPadPanel class], @selector(edge_step:));
  eminus.tag = 0;
  UIButton *eplus = mk_button(@"+", CGRectMake(pw - 92, 112, 68, 50), [KeyPadPanel class], @selector(edge_step:));
  eplus.tag = 1;
  g_edgev = [[UILabel alloc] initWithFrame:CGRectMake(96, 112, pw - 192, 50)];
  g_edgev.textColor = [UIColor colorWithRed:0.4 green:0.85 blue:1.0 alpha:1];
  g_edgev.textAlignment = NSTextAlignmentCenter;
  g_edgev.font = [UIFont monospacedDigitSystemFontOfSize:26 weight:UIFontWeightBold];

  g_debug = [[UILabel alloc] initWithFrame:CGRectMake(0, 168, pw, 22)];
  g_debug.textColor = [UIColor colorWithWhite:0.6 alpha:1];
  g_debug.textAlignment = NSTextAlignmentCenter;
  g_debug.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];

  UIButton *done = mk_button(@"完成", CGRectMake(pw / 2 - 44, 194, 88, 34), [KeyPadPanel class], @selector(close:));
  done.titleLabel.font = [UIFont boldSystemFontOfSize:16];

  for (UIView *v in @[ minus, plus, g_val, t2, eminus, eplus, g_edgev, g_debug, done ])
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
    g_edgep = (float *)((uintptr_t)base + EDGE_OFF);
    g_raw = *g_edgep;
    cfg_load();
    g_e0 = g_raw; g_e0_ok = YES;
    apply_all();
    guard_timer();
    install_touch_fix();
    NSLog(@"[keypad] base=%p k=%.2f edge=%.0f raw=%.0f", base, g_k, g_edge, g_raw);
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
