//
//  main.m
//  PristineTouch
//  Original author: github.com/gltchitm
//  Recreated by Turann_ on 30.06.2023.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        AppDelegate *appDelegate = [[AppDelegate alloc] init];
        [application setDelegate:appDelegate];
        
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 200, 200)
                                                       styleMask:NSWindowStyleMaskTitled
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        [window setTitle:@"Keyboard Cleaner"];
        [window makeKeyAndOrderFront:nil];
        
        [application run];
    }
    
    return NSApplicationMain(argc, argv);
}
