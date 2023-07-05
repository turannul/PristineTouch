//
// PristineTouch.m
// PristineTouch
// Original author: github.com/gltchitm
// Recreated by Turann_ on 30.06.2023.
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
    if (![self hasAccessibilityAccess]) {
        [self displayAccessibilityAlert];
        return;
    }

    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    NSOperatingSystemVersion osVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *OSXVer = [NSString stringWithFormat:@"%ld.%ld.%ld", (long)osVersion.majorVersion, (long)osVersion.minorVersion, (long)osVersion.patchVersion];

    NSLog(@"[*] macOS: %@", OSXVer);

    [self.window orderFront:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [NSCursor hide];
    [self blockHIDEvents];
    //if (@available(macOS 10.13.0, *)) {self.window.touchBar = [self makeTouchBar];} /* That's not working :( */
}

- (BOOL)hasAccessibilityAccess {
    BOOL accessibilityAccess = AXIsProcessTrusted();
    NSLog(@"[*] Accessibility perm: %d", accessibilityAccess);
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

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Missing permission"];
    [alert setInformativeText:@"Due to 'security' restrictions, you need to grant accessibility permission in order to block HID (Human Interface Devices) events."];
    [alert addButtonWithTitle:@"Allow"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleCritical];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            NSLog(@"[+] Someone allowed, :') ");
            NSURL *securityPrefsURL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"];
            [[NSWorkspace sharedWorkspace] openURL:securityPrefsURL];
        } else if (returnCode == NSAlertSecondButtonReturn) {
            NSLog(@"[-] Oops that's not supposed to happen, what now?\nAbort, abort :( )");
            exit(1);
        }
    }];
}



- (void)blockHIDEvents {
    CGEventMask eventMask = CGEventMaskBit(kCGEventKeyDown) |
                            CGEventMaskBit(kCGEventKeyUp) |
                            CGEventMaskBit(kCGEventMouseMoved) |
                            CGEventMaskBit(kCGEventLeftMouseDown) |
                            CGEventMaskBit(kCGEventRightMouseDown) |
                            CGEventMaskBit(kCGEventOtherMouseDown) |
                            CGEventMaskBit(kCGEventLeftMouseUp) |
                            CGEventMaskBit(kCGEventRightMouseUp) |
                            CGEventMaskBit(kCGEventOtherMouseUp) |
                            CGEventMaskBit(kCGEventScrollWheel) |
                            CGEventMaskBit(kCGEventFlagsChanged);

    CFMachPortRef eventTap = CGEventTapCreate(kCGSessionEventTap,
                                              kCGTailAppendEventTap,
                                              kCGEventTapOptionDefault,
                                              eventMask,
                                              eventTapCallBack,
                                              NULL);

    if (!eventTap) {
        NSLog(@"[!] Failed to create event tap");
        exit(1);
    }

    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);
    CFRunLoopRun();
}

CGEventRef eventTapCallBack(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    if (type != kCGEventTapDisabledByTimeout && type != kCGEventTapDisabledByUserInput) {
        CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

        if (keyCode == 12 && // Hardcoded value for Q key
            (CGEventGetFlags(event) & kCGEventFlagMaskCommand) &&
            (CGEventGetFlags(event) & kCGEventFlagMaskAlternate)) {
            exit(0); /* Exit when Cmd + Option + Q is pressed */
        }

        if (CGEventGetType(event) == kCGEventKeyDown || CGEventGetType(event) == kCGEventKeyUp) {
            return NULL;  /* Ignore keyboard events */
        }
    }

    return event;
}

- (NSString *)getModelIdentifier {
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
    NSString *modelIdentifier = [self getModelIdentifier];

    NSImage *lockIcon = nil;
    if ([modelIdentifier containsString:@"Book"]) /* Simple logic if contains "book" its a MacBook Pro/Air or Mac Mini if none true then its an iMac %100 */ {
        lockIcon = [NSImage imageWithSystemSymbolName:@"lock.laptopcomputer" accessibilityDescription:@"No1readthis"];
    } else if ([modelIdentifier containsString:@"Mini"]) {
        lockIcon = [NSImage imageWithSystemSymbolName:@"lock.display" accessibilityDescription:@"No1readthis"];
    } else if ([modelIdentifier containsString:@"iMac"]) {
        lockIcon = [NSImage imageWithSystemSymbolName:@"lock.desktopcomputer" accessibilityDescription:@"No1readthis"];
    } else {
        lockIcon = [NSImage imageWithSystemSymbolName:@"lock.fill" accessibilityDescription:@"No1readthis"]; /* 4.th option if none above is true (which very unlikely unless a Mac Pro) it will show a generic lock icon. */
    }
    return lockIcon;
}
/* 
// Even i disabled touchbar (well i tried) if you have one 
- (NSTouchBar *)makeTouchBar {
    if (@available(macOS 10.13.0, *)) {
        NSTouchBar *touchBar = [[NSTouchBar alloc] init];
        touchBar.delegate = self;
        touchBar.customizationIdentifier = @".CustomTouchBar";
        touchBar.defaultItemIdentifiers = @[];
        touchBar.principalItemIdentifier = nil;
        return touchBar; } else { return nil; }}
        */

@end