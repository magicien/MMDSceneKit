//
//  MMDCameraNode.swift
//  MMDSceneKit
//
//  Created by magicien on 11/14/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit

public let MMD_CAMERA_NODE_NAME = "MMDCamera"
public let MMD_CAMERA_ROT_NODE_NAME = "MMDCameraRotY"

open class MMDCameraNode: MMDNode {
    public init(name: String) {
        super.init()
        
        let cameraNode = MMDNode()
        let camera = SCNCamera()
        camera.name = name
        cameraNode.name = MMD_CAMERA_NODE_NAME
        cameraNode.camera = camera
        
        // TODO: set default values of MikuMikuDance: ex) fov
        camera.yFov = 45.0
        camera.automaticallyAdjustsZRange = true
        
        let rotNode = MMDNode()
        rotNode.name = MMD_CAMERA_ROT_NODE_NAME
        
        self.addChildNode(rotNode)
        rotNode.addChildNode(cameraNode)
    }
    
    public override convenience init() {
        self.init(name: "")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
