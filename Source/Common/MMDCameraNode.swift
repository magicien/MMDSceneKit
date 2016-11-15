//
//  MMDCameraNode.swift
//  MMDSceneKit
//
//  Created by magicien on 11/14/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit

public let MMD_CAMERA_NODE_NAME = "MMDCamera"

open class MMDCameraNode: MMDNode {
    public init(name: String) {
        super.init()
        
        let cameraNode = MMDNode()
        let camera = SCNCamera()
        camera.name = name

        cameraNode.name = MMD_CAMERA_NODE_NAME
        cameraNode.camera = camera
        self.addChildNode(cameraNode)
    }
    
    public override convenience init() {
        self.init(name: "")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
