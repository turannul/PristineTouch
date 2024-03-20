//
// PristineTouch.h
// PristineTouch
// Original author: github.com/gltchitm
// Recreated by Turann_ on 30.06.2023.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

@interface PristineTouch : NSWindowController <NSApplicationDelegate, NSTouchBarDelegate>

@property (strong) NSStatusItem *statusItem;
@property (strong) NSWindowController *preferencesWindowController;

- (BOOL)hasAccessibilityAccess;
- (void)displayAccessibilityAlert;
- (void)displayEventError;
- (void)blockHIDEvents;
- (void)setUpWindow;
- (NSTouchBar *)makeTouchBar;
- (NSString *)getMacModel;
- (NSImage *)determineLockIconForMacModel;

@end
