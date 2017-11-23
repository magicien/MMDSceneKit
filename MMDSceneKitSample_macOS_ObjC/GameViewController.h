//
//  GameViewController.h
//  MMDSceneKitSample_macOS_ObjC
//
//  Created by magicien on 11/15/17.
//  Copyright © 2017 DarkHorse. All rights reserved.
//

#import <SceneKit/SceneKit.h>
@import MMDSceneKit_macOS;

#import "MMDSceneViewController.h"
#import "GameView.h"

@interface GameViewController : MMDSceneViewController

@property IBOutlet GameView *gameView;

@end
