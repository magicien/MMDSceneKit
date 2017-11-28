//
//  InterfaceController.swift
//  MMDSceneKitSample_watchOS Extension
//
//  Created by Yuki OHNO on 11/9/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import WatchKit
import Foundation

class InterfaceController: MMDSceneViewController {

    @IBOutlet var scnInterface: WKInterfaceSCNScene!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        self.setupGameScene(SCNScene(), view: self.scnInterface)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
