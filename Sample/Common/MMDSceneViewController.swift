//
//  MMDSceneViewController.swift
//  MMDSceneKit
//
//  Created by magicien on 2/13/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit
#if os(OSX)
    import MMDSceneKit_OSX
    public typealias SuperViewController = NSViewController
#elseif os(iOS)
    import MMDSceneKit_iOS
    public typealias SuperViewController = UIViewController
#endif

public class MMDSceneViewController: SuperViewController, SCNSceneRendererDelegate {
    
    /**
     * setup game scene
     */
    public func setupGameScene(scene: SCNScene, view: SCNView) {
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
        #if os(OSX)
            ambientLightNode.light!.color = NSColor.darkGrayColor()
        #elseif os(iOS)
            ambientLightNode.light!.color = UIColor.darkGrayColor()
        #endif

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
        let motion = motionSceneSource?.animations().first?.1
        motion!.removedOnCompletion = false
        motion!.repeatCount = Float.infinity
        modelNode.addAnimation(motion!, forKey: "happysyn")
        
        modelNode.childNodes[0].position = SCNVector3Make(0, 50.0, 0.0)
        
        
        view.delegate = self

        // set the scene to the view
        view.scene = scene
        
        // allows the user to manipulate the camera
        view.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        view.showsStatistics = true
        
        // configure the view
        #if os(OSX)
            view.backgroundColor = NSColor.blackColor()
        #elseif os(iOS)
            view.backgroundColor = UIColor.blackColor()
        #endif

        /*
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        scnView.delegate = self
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        
        // set the scene to the view
        self.gameView!.scene = scene
        
        // allows the user to manipulate the camera
        self.gameView!.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        self.gameView!.showsStatistics = true
        
        // configure the view
        self.gameView!.backgroundColor = NSColor.blackColor()

        
        // configure the view
        #if os(OSX)
            scnView.backgroundColor = NSColor.blackColor()
        #elseif os(iOS)
            scnView.backgroundColor = UIColor.blackColor()
        #endif
        */
    }
    
    /**
     * apply IK constraint after animations are applied
     */
    public func renderer(renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: NSTimeInterval) {
        applyIKRecursive(scene.rootNode)
    }
    
    /**
     * apply IK constraint recursively
     */
    func applyIKRecursive(node: SCNNode) {
        if let mmdNode = node as? MMDNode {
            mmdNode.updateIK()
        }
        
        for childNode in node.childNodes {
            applyIKRecursive(childNode)
        }
    }

    /*
    func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        //print("didSimulatePhysicsAtTime")
    }
    func renderer(renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        //print("willRenderScene")
    }
    func renderer(renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        //print("didRenderScene")
    }
    */
}
