//
//  MMDCameraNode.swift
//  MMDSceneKit
//
//  Created by magicien on 11/14/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit

public let MMD_CAMERA_NODE_NAME = "MMDCamera"
public let MMD_CAMERA_ROTX_NODE_NAME = "MMDCameraRotX"
public let MMD_CAMERA_ROTY_NODE_NAME = "MMDCameraRotY"
public let MMD_CAMERA_ROTZ_NODE_NAME = "MMDCameraRotZ"

open class MMDCameraNode: MMDNode {
    public init(name: String) {
        super.init()
        
        let cameraNode = MMDNode()
        let camera = SCNCamera()
        camera.name = name
        cameraNode.name = MMD_CAMERA_NODE_NAME
        cameraNode.camera = camera
        
        // TODO: set default values of MikuMikuDance: ex) fov
        camera.yFov = 30.0
        camera.automaticallyAdjustsZRange = true
        
        let rotXNode = MMDNode()
        rotXNode.name = MMD_CAMERA_ROTX_NODE_NAME
        self.addChildNode(rotXNode)
        
        let rotZNode = MMDNode()
        rotZNode.name = MMD_CAMERA_ROTZ_NODE_NAME
        rotXNode.addChildNode(rotZNode)
        
        rotZNode.addChildNode(cameraNode)
    }
    
    public override convenience init() {
        self.init(name: "")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
