// keypad.m —— 注入到 WMMT 可执行文件的按键布局补丁（dylib）
//
// 原理：主程序把按键缩放系数放在一个全局 float（KEY_K，初值 1.0）里，
// hud_draw 画按键、hud_touch 判命中都读它。所以只要在运行时改这个变量，
// 按键大小就立刻变，命中区域同步跟着变，不用改一条指令。
//
// 交互：三指轻点屏幕 -> 弹出面板；面板上 [-]/[+] 调大小，改完立刻生效，
// 自动写回 Documents/keylayout.txt，下次启动读回来。

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach/mach.h>

#define KEYK_OFFSET 0x556040ULL /* _KEY_K 的 vmaddr(0x100556040) - 镜像基址(0x100000000) */

static float *g_keyk = NULL;
static float g_k = 1.0f;
static UIView *g_panel = nil;
static UILabel *g_val = NULL;

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
    }
  }
}

static void cfg_save(void) {
  NSString *p = cfg_path();
  if (!p) return;
  NSString *s = [NSString stringWithFormat:@"k=%.3f\n", g_k];
  [s writeToFile:p atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

#pragma mark - 生效

static void apply_k(void) {
  if (g_keyk) *g_keyk = g_k;
  if (g_val) g_val.text = [NSString stringWithFormat:@"%.2f", g_k];
}

/* 游戏在窗口尺寸变化时会用 hud_wide 把 KEY_K 写回 1.0，这里每半秒守一次 */
static void guard_timer(void) {
  dispatch_source_t t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                               dispatch_get_main_queue());
  dispatch_source_set_timer(t, dispatch_time(DISPATCH_TIME_NOW, 0),
                            500ull * NSEC_PER_MSEC, 50ull * NSEC_PER_MSEC);
  dispatch_source_set_event_handler(t, ^{
    if (g_keyk && *g_keyk != g_k) *g_keyk = g_k;
  });
  dispatch_resume(t);
}

#pragma mark - 面板

static UIButton *mk_button(NSString *title, CGRect r, id target, SEL sel) {
  UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
  b.frame = r;
  [b setTitle:title forState:UIControlStateNormal];
  [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  b.titleLabel.font = [UIFont boldSystemFontOfSize:22];
  b.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.16];
  b.layer.cornerRadius = 10;
  [b addTarget:target action:sel forControlEvents:UIControlEventTouchUpInside];
  return b;
}

@interface KeyPadPanel : NSObject
+ (void)toggle;
+ (void)step:(UIButton *)b;
+ (void)close:(UIButton *)b;
@end

@implementation KeyPadPanel

+ (void)step:(UIButton *)b {
  g_k += (b.tag == 1 ? 0.05f : -0.05f);
  if (g_k < 0.6f) g_k = 0.6f;
  if (g_k > 1.6f) g_k = 1.6f;
  apply_k();
  cfg_save();
}

+ (void)close:(UIButton *)b {
  [UIView animateWithDuration:0.18 animations:^{ g_panel.alpha = 0; }
                   completion:^(BOOL f) { g_panel.hidden = YES; g_panel.alpha = 1; }];
}

+ (void)toggle {
  if (g_panel) {
    g_panel.hidden = !g_panel.hidden;
    if (!g_panel.hidden) apply_k();
    return;
  }
  UIWindow *w = [UIApplication sharedApplication].windows.firstObject;
  if (!w) return;

  CGRect f = w.bounds;
  CGFloat pw = 300, ph = 170;
  g_panel = [[UIView alloc] initWithFrame:CGRectMake((f.size.width - pw) / 2,
                                                    f.size.height - ph - 60, pw, ph)];
  g_panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.86];
  g_panel.layer.cornerRadius = 18;
  g_panel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                             UIViewAutoresizingFlexibleRightMargin |
                             UIViewAutoresizingFlexibleTopMargin;

  UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 14, pw, 26)];
  title.text = @"按键大小";
  title.textColor = [UIColor whiteColor];
  title.textAlignment = NSTextAlignmentCenter;
  title.font = [UIFont boldSystemFontOfSize:18];
  [g_panel addSubview:title];

  UIButton *minus = mk_button(@"−", CGRectMake(30, 54, 70, 54), [KeyPadPanel class],
                              @selector(step:));
  minus.tag = 0;
  UIButton *plus = mk_button(@"+", CGRectMake(pw - 100, 54, 70, 54), [KeyPadPanel class],
                             @selector(step:));
  plus.tag = 1;

  g_val = [[UILabel alloc] initWithFrame:CGRectMake(100, 54, pw - 200, 54)];
  g_val.text = [NSString stringWithFormat:@"%.2f", g_k];
  g_val.textColor = [UIColor colorWithRed:1.0 green:0.62 blue:0.1 alpha:1];
  g_val.textAlignment = NSTextAlignmentCenter;
  g_val.font = [UIFont monospacedDigitSystemFontOfSize:26 weight:UIFontWeightBold];

  UIButton *done = mk_button(@"完成", CGRectMake(pw / 2 - 60, 122, 120, 36),
                             [KeyPadPanel class], @selector(close:));
  done.titleLabel.font = [UIFont boldSystemFontOfSize:17];

  [g_panel addSubview:minus];
  [g_panel addSubview:plus];
  [g_panel addSubview:g_val];
  [g_panel addSubview:done];
  [w addSubview:g_panel];
  apply_k();
}

@end

#pragma mark - 三指轻点唤出

@interface KeyPadGesture : NSObject
@end

@implementation KeyPadGesture
- (void)tapped:(UITapGestureRecognizer *)g {
  [KeyPadPanel toggle];
}
@end

static KeyPadGesture *g_gest = nil;

static void install_gesture(void) {
  UIWindow *w = [UIApplication sharedApplication].windows.firstObject;
  if (!w) return;
  g_gest = [KeyPadGesture new];
  UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc] initWithTarget:g_gest
                                                                     action:@selector(tapped:)];
  t.numberOfTouchesRequired = 3;
  t.cancelsTouchesInView = NO;
  t.delaysTouchesBegan = NO;
  t.delaysTouchesEnded = NO;
  [w addGestureRecognizer:t];
}

#pragma mark - 定位主程序并启动

static void *main_image_base(void) {
  uint32_t n = _dyld_image_count();
  for (uint32_t i = 0; i < n; ++i) {
    const struct mach_header *h = _dyld_get_image_header(i);
    if (h && h->filetype == MH_EXECUTE) {
      return (void *)((uintptr_t)h + (uintptr_t)_dyld_get_image_vmaddr_slide(i));
    }
  }
  return NULL;
}

__attribute__((constructor)) static void keypad_init(void) {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2500ull * NSEC_PER_MSEC),
                 dispatch_get_main_queue(), ^{
    void *base = main_image_base();
    if (!base) return;
    g_keyk = (float *)((uintptr_t)base + KEYK_OFFSET);
    cfg_load();
    apply_k();
    guard_timer();
    install_gesture();
    NSLog(@"[keypad] ready base=%p keyk=%p k=%.2f", base, g_keyk, g_k);
  });
}
