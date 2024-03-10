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
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    if (![self hasAccessibilityAccess]) { [self displayAccessibilityAlert]; }

    NSLog(@"Hello World, PristineTouch is running on macOS %ld.%ld.%ld",
            [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion,
            [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion,
            [[NSProcessInfo processInfo] operatingSystemVersion].patchVersion);

    [self.window orderFront:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [NSCursor hide];
    [self blockHIDEvents];
}

- (BOOL)hasAccessibilityAccess {
    BOOL accessibilityAccess = AXIsProcessTrusted();
    NSLog(@"Accessibility permission is %@", accessibilityAccess ? @"granted" : @"not granted :(");
    return accessibilityAccess;
}

- (void)displayAccessibilityAlert {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [self.window setBackgroundColor:[NSColor whiteColor]];
    [self.window setHasShadow:TRUE];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.window setContentSize:NSMakeSize(500, 500)];
    [self.window setStyleMask:NSWindowStyleMaskTitled];
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorDefault];
    [self.window center];
    [NSCursor unhide];

    NSAlert *AccessibilityMiss = [[NSAlert alloc] init];
    [AccessibilityMiss setMessageText:@"Missing permission"];
    [AccessibilityMiss setInformativeText:@"Because of security restrictions, Accessibility permission is required to restrict HID (Human Interface Device) events."];
    [AccessibilityMiss addButtonWithTitle:@"Allow"];
    [AccessibilityMiss addButtonWithTitle:@"Don't Allow - (Exit)"];
    [AccessibilityMiss setAlertStyle:NSAlertStyleCritical];
    [AccessibilityMiss beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            NSURL *securityPrefsURL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"];
            [[NSWorkspace sharedWorkspace] openURL:securityPrefsURL];
        } else if (returnCode == NSAlertSecondButtonReturn) {
            exit(0);
        }
    }];
}

- (void)blockHIDEvents {
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

    if (!eventTap) {
        NSAlert *eventTapErr = [[NSAlert alloc] init];
        NSString *ErrTitle = @"Critical Error - PristineTouch can't start.";
        NSString *ErrMsg = @"Something went terribly wrong.\nIf this message appears frequently, please report it to github.com/turannul/PristineTouch.";

        [eventTapErr setMessageText:ErrTitle];
        [eventTapErr setInformativeText:ErrMsg];
        [eventTapErr addButtonWithTitle:@"OK - Exit"];
        [eventTapErr setAlertStyle:NSAlertStyleWarning];
        [eventTapErr beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                exit(420); // Now we have proper exit.
            }
        }];
    }

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

- (NSString *)getMacmodel {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/sysctl"];
    [task setArguments:@[@"-n", @"hw.model"]];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *fileHandle = [pipe fileHandleForReading];
    [task launch];
    NSData *data = [fileHandle readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    output = [output stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return output;
}

- (NSImage *)determineLockIconForMacModel {
  NSString *modelIdentifier = [self getMacmodel];
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