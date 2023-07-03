//
// PristineTouch.h
// PristineTouch
// Original author: github.com/gltchitm
// Recreated by Turann_ on 30.06.2023.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

@interface PristineTouch : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSWindow *window;
@property (strong) NSStatusItem *statusItem;
@property (strong) NSWindowController *preferencesWindowController;

- (BOOL)hasAccessibilityAccess;
- (void)displayAccessibilityAlert;
- (void)blockHIDEvents;
- (NSString *)getModelIdentifier;
- (NSImage *)determineLockIconForMacModel;

@end
