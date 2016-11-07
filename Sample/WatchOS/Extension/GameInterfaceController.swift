//
//  GameInterfaceController.swift
//  MMDSceneKitSample_watchOS Extension
//
//  Created by magicien on 7/15/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import WatchKit
import Foundation

import SceneKit
import MMDSceneKit_watchOS

@available(watchOSApplicationExtension 3.0, *)
class GameInterfaceController: MMDSceneViewController {
    
    @IBOutlet var sceneInterface: WKInterfaceSCNScene!

    override func awake(withContext context: Any?) {
        print("***** GameInterfaceController awake *****")
        super.awake(withContext: context)
        return
        
        // Configure interface objects here.
        self.setupGameScene(sceneInterface.scene!, view: nil)
        print("***** GameInterfaceController setupGameScene end *****")
    }

    override func willActivate() {
        print("***** GameInterfaceController willActivate *****")
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        print("***** GameInterfaceController didDeactivate *****")
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
