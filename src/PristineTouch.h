//
// PristineTouch.h
// PristineTouch
// Original author: github.com/gltchitm
// Updated by Turann_ on 30.06.2023.


#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

@interface PristineTouch : NSWindowController <NSApplicationDelegate, NSTouchBarDelegate>

@property (strong) NSStatusItem *statusItem;
@property (strong) NSWindowController *preferencesWindowController;

- (BOOL)hasAccessibilityAccess;
- (BOOL)hasTouchBar;
- (void)displayAccessibilityAlert;
- (void)displayEventError;
- (void)blockHIDEvents;
- (void)setUpWindow;
- (NSString *)getMacModel;
- (NSImage *)determineLockIconForMacModel;

@end
