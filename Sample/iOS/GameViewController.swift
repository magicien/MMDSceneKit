//
//  GameViewController.swift
//  MMDSceneKitSample_iOS
//
//  Created by magicien on 12/10/15.
//  Copyright (c) 2015 DarkHorse. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import MMDSceneKit_iOS

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.automaticallyAdjustsZRange = true
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 50, z: 40)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 100, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        let modelPath = NSBundle.mainBundle().pathForResource("art.scnassets/miku", ofType: ".pmd")
        let modelSceneSource = MMDSceneSource(path: modelPath!)
        let modelNode = modelSceneSource!.modelNodes().first!
        scene.rootNode.addChildNode(modelNode)
        
        let xPath = NSBundle.mainBundle().pathForResource("art.scnassets/ゲキド街v3.0", ofType: ".x")
        let xSceneSource = MMDSceneSource(path: xPath!)
        let xNode = xSceneSource!.modelNodes().first!
        xNode.scale = SCNVector3Make(10.0, 10.0, 10.0)
        scene.rootNode.addChildNode(xNode)
        
        // animate the 3d object
        let motionPath = NSBundle.mainBundle().pathForResource("art.scnassets/running", ofType: ".vmd")
        let motionSceneSource = MMDSceneSource(path: motionPath!)
        //let animations = motionSceneSource?.animations()
        let motion = motionSceneSource?.animations().first?.1
        motion!.removedOnCompletion = false
        motion!.repeatCount = Float.infinity
        modelNode.addAnimation(motion!, forKey: "happysyn")
        
        //modelNode.position = SCNVector3Make(100.0, 100.0, 0.0)
        modelNode.childNodes[0].position = SCNVector3Make(0, 50.0, 0.0)

        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.blackColor()
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        scnView.addGestureRecognizer(tapGesture)
    }
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.locationInView(scnView)
        let hitResults = scnView.hitTest(p, options: nil)
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject! = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.setAnimationDuration(0.5)
            
            // on completion - unhighlight
            SCNTransaction.setCompletionBlock {
                SCNTransaction.begin()
                SCNTransaction.setAnimationDuration(0.5)
                
                material.emission.contents = UIColor.blackColor()
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.redColor()
            
            SCNTransaction.commit()
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
