//
//  MMDSceneViewController.h
//  MMDSceneKitSample_macOS_ObjC
//
//  Created by magicien on 11/15/17.
//  Copyright © 2017 DarkHorse. All rights reserved.
//

#ifndef MMDSceneViewController_h
#define MMDSceneViewController_h

#import <SceneKit/SceneKit.h>
@import MMDSceneKit_macOS;

typedef NSViewController SuperViewController;
typedef SCNView MMDView;

@interface MMDSceneViewController : SuperViewController

- (void)setupGameScene:(SCNScene *)scene view:(MMDView *)view;

@end

#endif /* MMDSceneViewController_h */
