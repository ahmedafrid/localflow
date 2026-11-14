#!/bin/bash
# Installs LocalFlow. Re-run after editing flow.py/ui.html.
#
# Why two parts: macOS ties Microphone/Accessibility/Input Monitoring to the app's exact signature.
# So the app bundle holds only the small launcher (rarely changes), and the code (flow.py, ui.html)
# lives in ~/Library/Application Support/LocalFlow/app. Editing code no longer resets your permissions;
# the bundle is only rebuilt when the launcher itself changes.
set -e
cd "$(dirname "$0")"
APP=/Applications/LocalFlow.app            # final location
NEW="$PWD/build/LocalFlow.app"             # staging copy, inside this folder
UV="$(command -v uv || echo "$HOME/.local/bin/uv")"
DATA="$HOME/Library/Application Support/LocalFlow"; mkdir -p "$DATA/app"
CODE="$DATA/app/flow.py"

# 1) code: copy, then restart LocalFlow so it runs the new version
cp flow.py ui.html "$DATA/app/"

# first build: carry over a key file from this folder
[ -f .env ] && ! grep -q "^OPENROUTER_API_KEY=." "$DATA/.env" 2>/dev/null && cp .env "$DATA/.env" && chmod 600 "$DATA/.env"

# 2) app bundle: built in ./build, installed only if it differs from what's installed
rm -rf "$PWD/build"                        # only our own staging folder
mkdir -p "$NEW/Contents/MacOS" "$NEW/Contents/Resources"
"$UV" run --quiet flow.py --make-icon "$PWD/build/LocalFlow.iconset"
iconutil -c icns "$PWD/build/LocalFlow.iconset" -o "$NEW/Contents/Resources/LocalFlow.icns"

# Tiny compiled launcher (macOS won't run a shell-script app). It is the real "LocalFlow" app:
# - starts uv/flow.py as a CHILD, so permissions you grant LocalFlow apply to it
# - owns the LocalFlow window (the page flow.py serves). Being the app macOS activates,
#   its window gets the keyboard, Cmd+V/C/X/A and a Dock icon while open
# - opening LocalFlow shows the window, except at login (starts quietly in the menu bar)
# - quits when flow.py quits
cat > "$PWD/build/launch.m" <<EOF
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include <spawn.h>
#include <sys/wait.h>
extern char **environ;
static pid_t child;
static NSWindow *win; static WKWebView *web; static int tries;
static NSString *data(NSString *f) {
  return [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/LocalFlow"] stringByAppendingPathComponent:f];
}
@interface D : NSObject <NSApplicationDelegate, NSWindowDelegate> @end
@implementation D
- (void)show {
  NSString *url = [[NSString stringWithContentsOfFile:data(@".ui-url") encoding:NSUTF8StringEncoding error:nil]
                    stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (!url.length) {  // flow.py still starting: try again shortly (up to ~60s)
    if (tries++ < 200) [self performSelector:@selector(show) withObject:nil afterDelay:0.3];
    return;
  }
  tries = 0;
  if (!win) {
    win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1000, 760)
             styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable
             backing:NSBackingStoreBuffered defer:NO];
    win.title = @"LocalFlow"; win.releasedWhenClosed = NO; win.minSize = NSMakeSize(420, 480); win.delegate = self;
    web = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:[WKWebViewConfiguration new]];
    win.contentView = web;
    [win center];
  }
  if (![web.URL.absoluteString isEqualToString:url]) [web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  [win makeKeyAndOrderFront:nil];
  [NSApp activateIgnoringOtherApps:YES];
}
- (void)windowWillClose:(NSNotification *)n { [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory]; }
- (void)applicationDidFinishLaunching:(NSNotification *)n {
  NSAppleEventDescriptor *e = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
  if ([[e paramDescriptorForKeyword:keyAEPropData] enumCodeValue] != keyAELaunchedAsLogInItem) [self show];
}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)a hasVisibleWindows:(BOOL)f { [self show]; return NO; }
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)a { return NO; }
- (void)applicationWillTerminate:(NSNotification *)n { kill(child, SIGTERM); }
@end
static void menu(void) {  // Edit menu = Cmd+V/C/X/A/Z work in the window
  NSMenu *bar = [NSMenu new];
  NSArray *defs = @[@[@"LocalFlow", @[@[@"Close Window", @"performClose:", @"w"], @[@"Quit LocalFlow", @"terminate:", @"q"]]],
                    @[@"Edit", @[@[@"Undo", @"undo:", @"z"], @[@"Redo", @"redo:", @"Z"], @[@"Cut", @"cut:", @"x"],
                                 @[@"Copy", @"copy:", @"c"], @[@"Paste", @"paste:", @"v"], @[@"Select All", @"selectAll:", @"a"]]]];
  for (NSArray *d in defs) {
    NSMenuItem *top = [NSMenuItem new]; NSMenu *sub = [[NSMenu alloc] initWithTitle:d[0]];
    for (NSArray *i in d[1]) [sub addItemWithTitle:i[0] action:NSSelectorFromString(i[1]) keyEquivalent:i[2]];
    top.submenu = sub; [bar addItem:top];
  }
  NSApp.mainMenu = bar;
}
int main(void) {
  @autoreleasepool {
    NSString *log = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/LocalFlow.log"];
    freopen(log.fileSystemRepresentation, "a", stdout); freopen(log.fileSystemRepresentation, "a", stderr);
    [[NSFileManager defaultManager] removeItemAtPath:data(@".ui-url") error:nil];  // flow.py writes a fresh one
    char *argv[] = {"uv", "run", "--quiet", "$CODE", NULL};
    if (posix_spawn(&child, "$UV", NULL, NULL, argv, environ) != 0) { perror("spawn uv"); return 1; }
    dispatch_source_t s = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, child, DISPATCH_PROC_EXIT, dispatch_get_main_queue());
    dispatch_source_set_event_handler(s, ^{ int st = 0; waitpid(child, &st, 0); exit(WIFEXITED(st) ? WEXITSTATUS(st) : 1); });
    dispatch_resume(s);
    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
    D *d = [D new]; app.delegate = d;
    menu();
    [app run];
  }
  return 0;
}
EOF
clang -O2 -fobjc-arc -framework Cocoa -framework WebKit -o "$NEW/Contents/MacOS/LocalFlow" "$PWD/build/launch.m"

cat > "$NEW/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>LocalFlow</string>
  <key>CFBundleIdentifier</key><string>local.localflow</string>
  <key>CFBundleExecutable</key><string>LocalFlow</string>
  <key>CFBundleIconFile</key><string>LocalFlow</string>
  <key>NSHumanReadableCopyright</key><string>Built by Ahmed Afrid</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>CFBundleShortVersionString</key><string>1.1</string>
  <key>LSUIElement</key><true/>
  <key>NSMicrophoneUsageDescription</key><string>LocalFlow listens while you hold Fn to turn your speech into text.</string>
</dict></plist>
EOF
FP=$(cat "$PWD/build/launch.m" "$NEW/Contents/Info.plist" "$NEW/Contents/Resources/LocalFlow.icns" | shasum | cut -c1-40)
echo "$FP" > "$NEW/Contents/Resources/fingerprint"

# stop the running copy (it is restarted below)
pkill -f "LocalFlow/app/flow.py" 2>/dev/null || true
pkill -f "LocalFlow.app/Contents/Resources/flow.py" 2>/dev/null || true
sleep 1

if [ "$(cat "$APP/Contents/Resources/fingerprint" 2>/dev/null)" = "$FP" ]; then
  echo "✓ App unchanged, permissions kept"
else
  codesign --force --deep -s - "$NEW"
  rm -rf "$APP"                            # only /Applications/LocalFlow.app
  mv "$NEW" "$APP"
  echo "✓ Installed new $APP (macOS may ask for permissions again, this time only)"
fi

osascript -e 'tell application "System Events" to if not (exists login item "LocalFlow") then make login item at end with properties {path:"/Applications/LocalFlow.app", hidden:true}' \
  >/dev/null || echo "! Add LocalFlow manually: System Settings → General → Login Items"
open "$APP"
echo "✓ LocalFlow running new code"
