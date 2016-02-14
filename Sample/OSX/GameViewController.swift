//
//  GameViewController.swift
//  MMDSceneKitSample_OSX
//
//  Created by magicien on 12/10/15.
//  Copyright (c) 2015 DarkHorse. All rights reserved.
//

import SceneKit
import QuartzCore
import MMDSceneKit_OSX

var scene: SCNScene! = nil

//let BitmaskStatic: Int = 1 << 1
//let BitmaskCollision: Int = 1 << 2


class GameViewController: MMDSceneViewController {
    
    @IBOutlet weak var gameView: GameView!
    
    override func awakeFromNib(){
        // create a new scene
        scene = SCNScene()
        
        self.setupGameScene(scene, view: self.gameView!)
    }
}
