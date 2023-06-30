//
//  AppDelegate.m
//  PristineTouch
//  Original author: github.com/gltchitm
//  Recreated by Turann_ on 30.06.2023.
//

#import "AppDelegate.h"

@implementation AppDelegate

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
        [self.window setLevel:NSFloatingWindowLevel];
        [self.window setCollectionBehavior:(NSWindowCollectionBehaviorStationary |
                                            NSWindowCollectionBehaviorIgnoresCycle |
                                            NSWindowCollectionBehaviorFullScreenNone)];
        [self.window setBackgroundColor:[NSColor blackColor]];

        NSRect deactivateFrame = NSMakeRect(0, 25, mainFrame.size.width, 0);
        NSText *deactivateLabel = [[NSText alloc] initWithFrame:deactivateFrame];
        [deactivateLabel setAlignment:NSTextAlignmentCenter];
        [deactivateLabel setFont:[NSFont systemFontOfSize:25.0]];
        [deactivateLabel setBackgroundColor:[NSColor clearColor]];
        [deactivateLabel setTextColor:[NSColor whiteColor]];
        [deactivateLabel setString:@"⌘ + ⌥ + Q to exit"];
        [deactivateLabel setSelectable:NO];

        NSImage *lockIcon = [self determineLockIconForMacModel];
        [lockIcon setSize:NSMakeSize(100, 100)];

        NSImageView *lockIconView = [NSImageView imageViewWithImage:lockIcon];
        [lockIconView setFrameSize:NSMakeSize(550, 550)];
        [lockIconView setSymbolConfiguration:[NSImageSymbolConfiguration configurationWithPointSize:100.0
                                                                                             weight:0.0]];
        [lockIconView setFrame:NSMakeRect((mainFrame.size.width - 100) / 2, (mainFrame.size.height - 100) / 2, 100, 100)];
        [lockIconView setContentTintColor:[NSColor whiteColor]];

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

    [self.window orderFront:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [NSCursor hide];
    [self blockMouseAndTrackpadEvents];
}

- (BOOL)hasAccessibilityAccess {
    BOOL accessibilityAccess = AXIsProcessTrusted();
    NSLog(@"Accessibility access: %d", accessibilityAccess);
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
    [alert setMessageText:@"Err! Missing permission"];
    [alert setInformativeText:@"Due to 'security' restrictions, you need to grant accessibility permission in order to block HID (Human Interface Devices) events."];
    [alert addButtonWithTitle:@"Alright, I'll allow it."];
    [alert addButtonWithTitle:@"No, I won't allow it."];
    NSLog(@"[!]: Failed to create event listener.\n Uh oh, no go :( exiting...");
    [alert setAlertStyle:NSAlertStyleCritical];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) { exit(1); }];
}

- (void)blockMouseAndTrackpadEvents {
    CGEventMask eventMask = (CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventMouseMoved) | CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventRightMouseDown));

    CGEventTapLocation tapLocation = kCGHIDEventTap;
    CGEventTapPlacement tapPlacement = kCGHeadInsertEventTap;
    CGEventTapOptions tapOptions = kCGEventTapOptionDefault;
    
    CFMachPortRef eventTap = CGEventTapCreate(tapLocation, tapPlacement, tapOptions, eventMask, tapCallback, NULL);
    if (!eventTap) {
        exit(1);
    }
    
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);
    CFRunLoopRun();
    CFRelease(eventTap);
    CFRelease(runLoopSource);
}

CGEventRef tapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    NSEvent *nsEvent = [NSEvent eventWithCGEvent:event];
    NSEventModifierFlags modifiers = [nsEvent modifierFlags];

    if ((type == kCGEventKeyDown) && ([[nsEvent.charactersIgnoringModifiers lowercaseString] isEqualToString:@"q"] && (modifiers & NSEventModifierFlagCommand) && (modifiers & NSEventModifierFlagOption))) {
        exit(0); /* kCGEventKeyDown = in simple terms when keyboard key pressed */
    }
    if ([nsEvent type] == NSEventTypeKeyDown || [nsEvent type] == NSEventTypeKeyUp) {
        return NULL;     /* Ignore keyboard events */
    }

    return event;
}

- (NSString *)getModelIdentifier {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:@[@"-c", @"system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}'"]];

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
        lockIcon = [NSImage imageWithSystemSymbolName:@"lock.laptopcomputer" accessibilityDescription:@"Locked MacBook"];
    } else if ([modelIdentifier containsString:@"Mini"]) {
        lockIcon = [NSImage imageWithSystemSymbolName:@"lock.display" accessibilityDescription:@"Locked Mac Mini"];
    } else {
        lockIcon = [NSImage imageWithSystemSymbolName:@"lock.desktopcomputer" accessibilityDescription:@"Locked iMac"];
    }
    return lockIcon;
}
@end
