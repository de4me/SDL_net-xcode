//
//  AppDelegate.m
//  chatObjectiveC
//
//  Created by DE4ME on 21.11.2021.
//

#import "AppDelegate.h"

@import SDL_net;


@interface AppDelegate ()

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    SDLNet_Init();
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    SDLNet_Quit();
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
