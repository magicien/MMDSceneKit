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
        // set the scene to the view
        view.scene = MMDSceneSource(named: "art.scnassets/サンプル（きしめんAllStar).pmm")!.getScene()!
        
        // show statistics such as fps and timing information
        view.showsStatistics = true
        
        #if !os(watchOS)
            // set the delegate to update IK for each frame
            view.delegate = MMDIKController.sharedController
        #endif
        
        // configure the view
        #if os(macOS)
            view.backgroundColor = NSColor.white
        #elseif os(iOS) || os(tvOS)
            view.backgroundColor = UIColor.white
        #endif
    }
}
