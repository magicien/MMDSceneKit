//
//  GameViewController.m
//  MMDSceneKitSample_macOS_ObjC
//
//  Created by magicien on 11/15/17.
//  Copyright © 2017 DarkHorse. All rights reserved.
//

#import "GameViewController.h"

@implementation GameViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    SCNScene *scene = [[SCNScene alloc] init];
    [self setupGameScene:scene view:self.gameView];
}

    /*
    // create a new scene
    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
    
    // create and add a camera to the scene
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    
    // place the camera
    cameraNode.position = SCNVector3Make(0, 0, 15);
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 10, 10);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [NSColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
    // retrieve the ship node
    SCNNode *ship = [scene.rootNode childNodeWithName:@"ship" recursively:YES];
    
    // animate the 3d object
    [ship runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:2 z:0 duration:1]]];
    
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    
    // set the scene to the view
    scnView.scene = scene;
    
    // allows the user to manipulate the camera
    scnView.allowsCameraControl = YES;
    
    // show statistics such as fps and timing information
    scnView.showsStatistics = YES;
    
    // configure the view
    scnView.backgroundColor = [NSColor blackColor];
    
    // Add a click gesture recognizer
    NSClickGestureRecognizer *clickGesture = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:clickGesture];
    [gestureRecognizers addObjectsFromArray:scnView.gestureRecognizers];
    scnView.gestureRecognizers = gestureRecognizers;
}

- (void)handleTap:(NSGestureRecognizer *)gestureRecognizer {
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    
    // check what nodes are tapped
    CGPoint p = [gestureRecognizer locationInView:scnView];
    NSArray *hitResults = [scnView hitTest:p options:nil];
    
    // check that we clicked on at least one object
    if ([hitResults count] > 0) {
        // retrieved the first clicked object
        SCNHitTestResult *result = [hitResults objectAtIndex:0];
        
        // get its material
        SCNMaterial *material = result.node.geometry.firstMaterial;
        
        // highlight it
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.5];
        
        // on completion - unhighlight
        [SCNTransaction setCompletionBlock:^{
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.5];
            
            material.emission.contents = [NSColor blackColor];
            
            [SCNTransaction commit];
        }];
        
        material.emission.contents = [NSColor redColor];
        
        [SCNTransaction commit];
    }
}
     */

@end
