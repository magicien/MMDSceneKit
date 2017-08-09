//
//  MMDCameraNode.swift
//  MMDSceneKit
//
//  Created by magicien on 11/14/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit

public let MMD_CAMERA_ROOT_NODE_NAME = "MMDCameraRoot"
public let MMD_CAMERA_NODE_NAME = "MMDCamera"
public let MMD_CAMERA_ROTX_NODE_NAME = "MMDCameraRotX"
public let MMD_CAMERA_ROTY_NODE_NAME = "MMDCameraRotY"
public let MMD_CAMERA_ROTZ_NODE_NAME = "MMDCameraRotZ"

open class MMDCameraNode: MMDNode {
    
    private var rotXNode: SCNNode! = nil
    private var rotYNode: SCNNode! = nil
    private var rotZNode: SCNNode! = nil
    private var cameraNode: SCNNode! = nil
    
    public var rotX: Float {
        get {
            return Float(self.rotXNode.eulerAngles.x)
        }
        set {
            self.rotXNode.eulerAngles.x = OSFloat(newValue)
        }
    }
    
    public var rotY: Float {
        get {
            return Float(self.rotYNode.eulerAngles.y)
        }
        set {
            self.rotYNode.eulerAngles.y = OSFloat(newValue)
        }
    }

    public var rotZ: Float {
        get {
            return Float(self.rotZNode.eulerAngles.z)
        }
        set {
            self.rotZNode.eulerAngles.z = OSFloat(newValue)
        }
    }
    
    public var distance: Float {
        get {
            return Float(self.cameraNode.position.z)
        }
        set {
            self.cameraNode.position.z = OSFloat(newValue)
        }
    }

    var angle: Double {
        get {
            return self.cameraNode.camera!.yFov
        }
        set {
            self.cameraNode.camera!.yFov = newValue
        }
    }
    
    public init(name: String = MMD_CAMERA_ROOT_NODE_NAME) {
        super.init()
        self.name = name
        
        self.cameraNode = MMDNode()
        let camera = SCNCamera()
        camera.name = name
        self.cameraNode.name = MMD_CAMERA_NODE_NAME
        self.cameraNode.camera = camera
        
        // TODO: set default values of MikuMikuDance: ex) fov
        camera.yFov = 30.0
        camera.automaticallyAdjustsZRange = true
        
        self.rotYNode = MMDNode()
        self.rotYNode.name = MMD_CAMERA_ROTY_NODE_NAME
        self.addChildNode(self.rotYNode)
        
        self.rotXNode = MMDNode()
        self.rotXNode.name = MMD_CAMERA_ROTX_NODE_NAME
        self.rotYNode.addChildNode(self.rotXNode)
        
        self.rotZNode = MMDNode()
        self.rotZNode.name = MMD_CAMERA_ROTZ_NODE_NAME
        self.rotXNode.addChildNode(self.rotZNode)
        
        self.rotZNode.addChildNode(self.cameraNode)
        
        #if !os(watchOS)
            // set technique
            //camera.technique = MMDTechnique()
            if let path = Bundle(for: MMDCameraNode.self).path(forResource: "MMDShader", ofType: "plist") {
                if let dict1 = NSDictionary(contentsOfFile: path) {
                    let dict = dict1 as! [String : AnyObject]
                    let technique = SCNTechnique(dictionary:dict)
                    camera.technique = technique
                }
            }
        #endif
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func getCameraNode() -> SCNNode {
        return self.cameraNode
    }
    
    public func getCamera() -> SCNCamera {
        return self.cameraNode.camera!
    }
}
