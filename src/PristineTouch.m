//
// PristineTouch.m
// PristineTouch
// Original author: github.com/gltchitm
// Updated by Turann_ on 30.06.2023.
//

#import "PristineTouch.h"

@implementation PristineTouch

- (instancetype)init {
    self = [super init];
    if (self) {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [self setUpWindow]; // Set up and create window
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    }
    return self;
}

- (void)setUpWindow {
        NSRect mainFrame = [[NSScreen mainScreen] frame];
        self.window = [[NSWindow alloc] initWithContentRect:mainFrame
                                                styleMask:NSWindowStyleMaskBorderless
                                                backing:NSBackingStoreBuffered
                                                defer:NO];
        
        [self.window setTitle:@"PristineTouch"];
        [self.window setLevel:kCGMaximumWindowLevel];

        [self.window setCollectionBehavior:(NSWindowCollectionBehaviorStationary |
                                            NSWindowCollectionBehaviorIgnoresCycle |
                                            NSWindowCollectionBehaviorFullScreenAuxiliary)];
        [self.window setBackgroundColor:[NSColor blackColor]];
        [self.window toggleFullScreen:nil];
        [NSMenu setMenuBarVisible:NO];
        
        NSRect deactivateFrame = NSMakeRect(0, 25, mainFrame.size.width, 0);
        NSText *deactivateLabel = [[NSText alloc] initWithFrame:deactivateFrame];
        [deactivateLabel setAlignment:NSTextAlignmentCenter];
        [deactivateLabel setFont:[NSFont systemFontOfSize:25.0]];
        [deactivateLabel setBackgroundColor:[NSColor clearColor]];
        [deactivateLabel setTextColor:[NSColor whiteColor]];
        [deactivateLabel setString:@"⌘ + ⌥ + Q to exit"];
        [deactivateLabel setSelectable:NO];
        
        NSImage *lockIcon = [self determineLockIconForMacModel];
        [lockIcon setSize:NSMakeSize(256, 256)];
        
        NSImageView *lockIconView = [NSImageView imageViewWithImage:lockIcon];
        [lockIconView setFrameSize:NSMakeSize(256, 256)];
        [lockIconView setSymbolConfiguration:[NSImageSymbolConfiguration configurationWithPointSize:256.0 weight:256.0]];
        [lockIconView setContentTintColor:[NSColor whiteColor]];
        
        CGFloat iconSize = 256.0;
        CGFloat iconX = (mainFrame.size.width - iconSize) / 2;
        CGFloat iconY = (mainFrame.size.height - iconSize) / 2;
        [lockIconView setFrame:NSMakeRect(iconX, iconY, iconSize, iconSize)];
        
        [[self.window contentView] addSubview:lockIconView];
        [[self.window contentView] addSubview:deactivateLabel];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSLog(@"Hello World, PristineTouch is running on macOS %ld.%ld.%ld",
            [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion,
            [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion,
            [[NSProcessInfo processInfo] operatingSystemVersion].patchVersion);
    if (![self hasAccessibilityAccess]){ 
        [self.window orderOut:nil]; // Do not show window here.
        [self displayAccessibilityAlert]; // Display alert
    } else {
        [self blockHIDEvents]; // Call blocking function (to start blocking HID events)
        if ([self hasTouchBar]) {
        NSTouchBar *touchBar = [self makeTouchBar];
        if (touchBar) {
            NSView *contentView = [[NSView alloc] initWithFrame:self.window.frame];
            [contentView addSubview:(NSView *)touchBar];  // Cast touchBar to NSView
            [self.window setContentView:contentView];
            }
        }
    }
}

- (NSTouchBar *)makeTouchBar {
  NSTouchBar *touchBar = [[NSTouchBar alloc] init];
  touchBar.delegate = self; // Set delegate (optional but recommended)
    touchBar.customizationIdentifier = @"xyz.turannul.pristinetouch-emptytouchbar";

  NSCustomTouchBarItem *emptyItem = [[NSCustomTouchBarItem alloc] initWithIdentifier:@"xyz.turannul.pristinetouch-emptytouchbar.view"];
  NSView *customView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 30)]; // Adjust frame size as needed
    customView.wantsLayer = YES;
    customView.layer.backgroundColor = [NSColor blueColor].CGColor;  // Access CGColor property

    emptyItem.view = customView;

    touchBar.defaultItemIdentifiers = @[emptyItem.identifier];
    touchBar.customizationAllowedItemIdentifiers = @[emptyItem.identifier];

    return touchBar;
}

- (BOOL)hasAccessibilityAccess {
    BOOL accessibilityAccess = AXIsProcessTrusted();
    NSLog(@"Accessibility permission is %@", accessibilityAccess ? @"granted" : @"not granted :(");
    return accessibilityAccess;
}

- (BOOL)hasTouchBar {
    NSTask *tbJob = [[NSTask alloc] init];
    [tbJob setLaunchPath:@"/usr/bin/pgrep"]; // pgrep is a command line utility that searches for processes by name
    // Note: If TouchBarServer process is active/running on the machine (very likely *I don't know simulators do use it*) has a TouchBar. Said likely for a reason checking for hardware is little bit complicated, and details not relevant to this program. - Work smarter, not harder.
    [tbJob setArguments:@[@"TouchBarServer"]]; // Search for "TouchBarServer"
    NSPipe *pipe = [NSPipe pipe]; // Create a pipe to read the output
    [tbJob setStandardOutput:pipe]; // Set the standard output to the pipe
    [tbJob launch]; // Launch the task
    [tbJob waitUntilExit]; // Wait for the task to finish
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile]; // Read the output
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]; // Convert the output to a NSString
    BOOL serverRunning = (output.length > 0); // Check if the output is not empty
    NSLog(@"The TouchBar is %@.", serverRunning ? @"available" : @"not available"); // Print the result
    return serverRunning; // Return the result
}

- (void)displayAccessibilityAlert {
    NSAlert *accessibilityAlert = [[NSAlert alloc] init];
    [accessibilityAlert setMessageText:@"Missing permission"];
    [accessibilityAlert setInformativeText:@"Because of security restrictions, Accessibility permission is required to restrict HID (Human Interface Device) events."];
    [accessibilityAlert addButtonWithTitle:@"Allow"];
    [accessibilityAlert addButtonWithTitle:@"Don't Allow - (Quit the app)"];
    [accessibilityAlert setAlertStyle:NSAlertStyleCritical];

    NSModalResponse response = [accessibilityAlert runModal];
    if (response == NSAlertFirstButtonReturn) {
        NSURL *securityPrefsURL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"];
        [[NSWorkspace sharedWorkspace] openURL:securityPrefsURL];
    } else if (response == NSAlertSecondButtonReturn) {
        exit(0);
    }
}

-(void)displayEventError {
    NSAlert *eventTapErr = [[NSAlert alloc] init];
    [eventTapErr setMessageText:@"Critical Error - PristineTouch can't start."];
    [eventTapErr setInformativeText:@"Something went terribly wrong.\nIf this message appears frequently, please report it at github.com/turannul/PristineTouch."];
    [eventTapErr addButtonWithTitle:@"Quit the app"];
    [eventTapErr setAlertStyle:NSAlertStyleCritical];

    NSModalResponse response = [eventTapErr runModal];
        if (response == NSAlertFirstButtonReturn) { exit(420); }
}

- (void)blockHIDEvents {
    [NSCursor hide]; // Hide the cursor while block running.
    CGEventMask eventMask = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) |
                            // Keyboard Events; key pressed/released
                            CGEventMaskBit(kCGEventMouseMoved) |
                            // Mouse Events; mouse moved/ keys pressed etc.
                            CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventLeftMouseUp) | CGEventMaskBit(kCGEventLeftMouseDragged) |
                            CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventRightMouseUp) | CGEventMaskBit(kCGEventRightMouseDragged) |
                            CGEventMaskBit(kCGEventOtherMouseDown) | CGEventMaskBit(kCGEventOtherMouseUp) | CGEventMaskBit(kCGEventOtherMouseDragged) |
                            CGEventMaskBit(kCGEventScrollWheel) |
                            CGEventMaskBit(kCGEventFlagsChanged);
                            // Modifier Key Changes = Shift, Control, Option, Command

    CFMachPortRef eventTap = CGEventTapCreate(kCGSessionEventTap,
                                                kCGTailAppendEventTap,
                                                kCGEventTapOptionDefault,
                                                eventMask,
                                                eventTapCallBack,
                                                NULL);

    if (!eventTap) { [self displayEventError]; } // Handling (very rare) error, where eventTap has null.

    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);
    CFRunLoopRun();
}

CGEventRef eventTapCallBack(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    if (type != kCGEventTapDisabledByTimeout && type != kCGEventTapDisabledByUserInput) {
            NSLog(@"Event: %@", event);

        // Ignore all events except exit shortcut
        if (!(type == kCGEventKeyDown || type == kCGEventKeyUp) ||
            !(CGEventGetFlags(event) & kCGEventFlagMaskCommand) ||
            !(CGEventGetFlags(event) & kCGEventFlagMaskAlternate)) {
            NSLog(@"Ignored: %@", event);
            return NULL;
        }

        // Exit shortcut: command + option + Q = (⌘ + ⌥ + Q) <Q = 12>
        CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        if (keyCode == 12) { exit(0); }
    }
    return event;  // Don't interrupt other event(s), that weren't explicitly ignored
}

- (NSString *)getMacModel {
    NSTask *cmd = [[NSTask alloc] init];
    [cmd setLaunchPath:@"/usr/sbin/sysctl"];
    [cmd setArguments:@[@"-n", @"hw.model"]];
    NSPipe *pipe = [NSPipe pipe];
    [cmd setStandardOutput:pipe];
    NSFileHandle *fileHandle = [pipe fileHandleForReading];
    [cmd launch];
    NSData *data = [fileHandle readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    output = [output stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return output;
}

- (NSImage *)determineLockIconForMacModel {
  NSString *modelIdentifier = [self getMacModel];
  NSImage *lockIcon = nil;

    if ([modelIdentifier hasPrefix:@"MacBook"]) {
        lockIcon = [NSImage imageWithSystemSymbolName:@"lock.laptopcomputer" accessibilityDescription:@"MacBook"];
    } else if ([modelIdentifier isEqualToString:@"Mac Mini"] || [modelIdentifier isEqualToString:@"Mac Studio"] || [modelIdentifier isEqualToString:@"Mac Pro"]) {
        lockIcon = [NSImage imageWithSystemSymbolName:@"lock.display" accessibilityDescription:@"MacWexternalDisplay"];
    } else if ([modelIdentifier hasPrefix:@"iMac"]) {
        lockIcon = [NSImage imageWithSystemSymbolName:@"lock.desktopcomputer" accessibilityDescription:@"iMac"];
    } else {
        lockIcon = [NSImage imageWithSystemSymbolName:@"lock.fill" accessibilityDescription:@"GenericMac"];
    }
return lockIcon;
}

@end