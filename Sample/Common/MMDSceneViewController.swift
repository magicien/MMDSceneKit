//
//  MMDSceneViewController.swift
//  MMDSceneKit
//
//  Created by magicien on 2/13/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit
#if os(OSX)
    import MMDSceneKit_macOS
    public typealias SuperViewController = NSViewController
    public typealias MMDView = SCNView
#elseif os(iOS)
    import MMDSceneKit_iOS
    public typealias SuperViewController = UIViewController
    public typealias MMDView = SCNView
#elseif os(watchOS)
    import MMDSceneKit_watchOS
    public typealias SuperViewController = WKInterfaceController
    public typealias MMDView = Any?
    
    //@objc protocol SCNSceneRendererDelegate {
    //    // not supported
    //}
#endif

public class MMDSceneViewController: SuperViewController, SCNSceneRendererDelegate {
    
    /**
     * setup game scene
     */
    public func setupGameScene(_ scene: SCNScene, view: MMDView) {
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
        lightNode.light!.type = SCNLight.LightType.omni
        lightNode.position = SCNVector3(x: 0, y: 100, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        #if os(OSX)
            ambientLightNode.light!.color = NSColor.darkGray
        #elseif os(iOS) || os(watchOS)
            ambientLightNode.light!.color = UIColor.darkGray
        #endif

        scene.rootNode.addChildNode(ambientLightNode)

        // create a character node from file
        let modelPath = Bundle.main.path(forResource: "art.scnassets/miku", ofType: ".pmd")
        let modelSceneSource = MMDSceneSource(path: modelPath!)
        let modelNode = modelSceneSource!.modelNodes().first!
        scene.rootNode.addChildNode(modelNode)
        
        // create a background object from file
        
        // measure time for optimization
        let timer = Date()
        let xPath = Bundle.main.path(forResource: "art.scnassets/ゲキド街v3.0", ofType: ".x")
        let xSceneSource = MMDSceneSource(path: xPath!)
        let xNode = xSceneSource!.modelNodes().first!
        xNode.scale = SCNVector3Make(10.0, 10.0, 10.0)
        scene.rootNode.addChildNode(xNode)
        print("Read XFile: \(-timer.timeIntervalSinceNow) sec.")
        
#if !os(watchOS)
        // animate the 3d object
        let motionPath = Bundle.main.path(forResource: "art.scnassets/walking", ofType: ".vmd")
        let motionSceneSource = MMDSceneSource(path: motionPath!)
        let motion = motionSceneSource?.animations().first?.1
        motion!.isRemovedOnCompletion = false
        motion!.repeatCount = Float.infinity
        modelNode.addAnimation(motion!, forKey: "happysyn")
#endif
    
        modelNode.childNodes[0].position = SCNVector3Make(0, 50.0, 0.0)
        
#if !os(watchOS)
        view.delegate = self

        // set the scene to the view
        view.scene = scene
        
        // allows the user to manipulate the camera
        view.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        view.showsStatistics = true
#endif
        
        // configure the view
        #if os(OSX)
            view.backgroundColor = NSColor.black
        #elseif os(iOS)
            view.backgroundColor = UIColor.black
        #endif
    }
    
    #if !os(watchOS)
    /**
     * apply IK constraint after animations are applied
     */
    public func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        applyIKRecursive(scene.rootNode)
    }
    #endif
    
    /**
     * apply IK constraint recursively
     */
    func applyIKRecursive(_ node: SCNNode) {
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
