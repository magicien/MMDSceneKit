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
#elseif os(tvOS)
    import MMDSceneKit_tvOS
    public typealias SuperViewController = UIViewController
    public typealias MMDView = SCNView
#elseif os(iOS)
    import MMDSceneKit_iOS
    public typealias SuperViewController = UIViewController
    public typealias MMDView = SCNView
#elseif os(watchOS)
    import MMDSceneKit_watchOS
    public typealias SuperViewController = WKInterfaceController
    public typealias MMDView = WKInterfaceSCNScene
#endif

var mikuNode: MMDNode! = nil

public class MMDSceneViewController: SuperViewController {
    
    /**
     * setup game scene
     */
    public func setupGameScene(_ scene: SCNScene, view: MMDView) {
        
        //let vpdData = MMDSceneSource(named: "art5.scnassets/右手グー.vpd")!.getMotion()!
        //return
        
        //let mmdScene = MMDSceneSource(named: "art3.scnassets/サンプル（きしめんAllStar).pmm")!.getScene()!
        
        #if !os(watchOS)
        print("shader...")
        if let path = Bundle.main.path(forResource: "MMDShader", ofType: "plist") {
            if let dict1 = NSDictionary(contentsOfFile: path) {
                print("found shader.")
                let dict = dict1 as! [String : AnyObject]
                let technique = SCNTechnique(dictionary:dict)
                print("technique: \(technique)")
                //var screenSize: Float = Float(max(view.frame.size.height, view.frame.size.width))
                
                //let customData = NSData(bytes: &screenSize, length: MemoryLayout<Float>.size)
                //technique?.setValue(customData, forKey: "screenSize")
                
                view.technique = technique
            }
        }
        #endif
        
        /*
        let mmdScene = MMDSceneSource(named: "art3.scnassets/宝箱開け.pmm")!.getScene()!
        view.scene = mmdScene
        view.delegate = MMDIKController.sharedController
        view.showsStatistics = true
        
        #if os(iOS)
        view.backgroundColor = UIColor.white
        #endif
        
        #if !os(watchOS)
        // allows the user to manipulate the camera
        view.allowsCameraControl = true
        #endif

        return
        */
        
        // create and add a camera to the scene
        //let cameraNode = SCNNode()
        //cameraNode.camera = SCNCamera()
        //cameraNode.camera?.automaticallyAdjustsZRange = true
        //scene.rootNode.addChildNode(cameraNode)
        let cameraNode = MMDCameraNode()
        scene.rootNode.addChildNode(cameraNode)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLight.LightType.directional
        //lightNode.light!.color = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lightNode.position = SCNVector3(x: 0, y: 100, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        /*
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        #if os(OSX)
            ambientLightNode.light!.color = NSColor.darkGray
        #elseif os(iOS) || os(tvOS) || os(watchOS)
            ambientLightNode.light!.color = UIColor.darkGray
        #endif

        scene.rootNode.addChildNode(ambientLightNode)
        */
        
        
        // create a character node from file
        //let modelNode = MMDSceneSource(named: "art1.scnassets/miku.pmd")!.getModel()!
        //let modelNode = MMDSceneSource(named: "art1.scnassets/初音ミク イミテーションｖ1ミニマム2.pmx")!.getModel()!
        //let modelNode = MMDSceneSource(named: "art1.scnassets/Tda式初音ミク・アペンド_Ver1.00_ボーン未改造.pmx")!.getModel()!
        let modelNode = MMDSceneSource(named: "art4.scnassets/una/音街ウナ（公式モデル）Sugar.pmx")!.getModel()!
        scene.rootNode.addChildNode(modelNode)
        mikuNode = modelNode
        
        //view.debugOptions = .showPhysicsShapes

        /*
        let debugPath = Bundle.main.path(forResource: "MMDPostShader", ofType: "plist")

        if let path = Bundle.main.path(forResource: "MMDPostShader", ofType: "plist") {
            if let dict1 = NSDictionary(contentsOfFile: path) {
                let dict = dict1 as! [String : AnyObject]
                let technique = SCNTechnique(dictionary:dict)
                view.technique = technique
            }
        }
         */
        
        // create a background object from file
        /*
#if !os(watchOS)
        // This X model is too big for watchOS...
    
        // measure time for optimization
        let timer = Date()
        let xNode = MMDSceneSource(named: "art2.scnassets/ゲキド街v3.0.x")!.getModel()!
        xNode.scale = SCNVector3Make(10.0, 10.0, 10.0)
        scene.rootNode.addChildNode(xNode)
        print("Read XFile: \(-timer.timeIntervalSinceNow) sec.")
#endif
         */

        let stage = MMDSceneSource(named: "art4.scnassets/DTE SPiCa Stage/1.pmx")!.getModel()!
        scene.rootNode.addChildNode(stage)
        
        
#if !os(watchOS)
        let cameraMotion = MMDSceneSource(named: "art4.scnassets/Shake it! Camera by RituPepper.vmd")!.getMotion()!

        // animate the 3d object
        //let motion = MMDSceneSource(named: "art2.scnassets/running.vmd")!.getMotion()!
        //let motion = MMDSceneSource(named: "art2.scnassets/AzatokawaiiTurn.vmd")!.getMotion()!
        let motion = MMDSceneSource(named: "art4.scnassets/shakeit_vmd/shakeit_miku.vmd")!.getMotion()!
        //motion.isRemovedOnCompletion = false
        //motion.repeatCount = Float.infinity
        //motion.usesSceneTimeBase = true
        modelNode.addAnimation(motion, forKey: "motion")
    
        cameraNode.addAnimation(cameraMotion, forKey: "shakeit")
#else
        // rotate the model instead of animating...
        modelNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
#endif
        
        //modelNode.childNodes[0].position = SCNVector3Make(0, 50.0, 0.0)
        modelNode.childNodes[0].position = SCNVector3Make(0.0, 0.0, 0.0)
        
        // place the camera
        //cameraNode.position = SCNVector3(x: 0, y: 50, z: 40)
        
        // set the scene to the view
        view.scene = scene
        
        // show statistics such as fps and timing information
        view.showsStatistics = true

#if !os(watchOS)
        // set the delegate to update IK for each frame
        view.delegate = MMDIKController.sharedController
    
        // allows the user to manipulate the camera
        view.allowsCameraControl = true
#endif

        // configure the view
        #if os(OSX)
            view.backgroundColor = NSColor.black
        #elseif os(iOS) || os(tvOS)
            view.backgroundColor = UIColor.black
        #endif
    }
}
