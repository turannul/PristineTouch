//
//  main.m
//  PristineTouch
//  Original author: github.com/gltchitm
//  Recreated by Turann_ on 30.06.2023.
//

#import "PristineTouch.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        PristineTouch *pristineTouchApp = [[PristineTouch alloc] init];
        [application setDelegate:pristineTouchApp];
        
        return NSApplicationMain(argc, argv);
    }
}
