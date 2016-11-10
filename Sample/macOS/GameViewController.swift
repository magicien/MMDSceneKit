//
//  GameViewController.swift
//  MMDSceneKitSample_macOS
//
//  Created by magicien on 12/10/15.
//  Copyright (c) 2015 DarkHorse. All rights reserved.
//

import SceneKit
import QuartzCore
import MMDSceneKit_macOS

var scene: SCNScene! = nil

class GameViewController: MMDSceneViewController {
    
    @IBOutlet weak var gameView: GameView!
    
    override func awakeFromNib(){
        // create a new scene
        scene = SCNScene()
        
        self.setupGameScene(scene, view: self.gameView!)
    }
}
