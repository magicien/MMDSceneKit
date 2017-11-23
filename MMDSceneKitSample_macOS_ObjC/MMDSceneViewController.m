//
//  MMDSceneViewController.m
//  MMDSceneKitSample_macOS_ObjC
//
//  Created by magicien on 11/15/17.
//  Copyright © 2017 DarkHorse. All rights reserved.
//

#import "MMDSceneViewController.h"

@implementation MMDSceneViewController

- (void)setupGameScene:(SCNScene *)scene view:(MMDView *)view {
    @autoreleasepool {
        MMDSceneSource *source = [[MMDSceneSource alloc] initWithNamed:@"art.scnassets/サンプル（きしめんAllStar).pmm" options:nil models:nil];
        view.scene = [source getScene];
        view.showsStatistics = true;
        
        view.delegate = MMDIKController.sharedController;
        
        view.backgroundColor = NSColor.whiteColor;
    }
}

@end
