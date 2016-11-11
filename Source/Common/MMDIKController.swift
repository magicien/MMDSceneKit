//
//  MMDIKController.swift
//  MMDSceneKit
//
//  Created by magicien on 11/10/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit

public class MMDIKController: NSObject, SCNSceneRendererDelegate {
    public static let sharedController = MMDIKController()
    
    /**
     * Init function is private for singleton
     */
    private override init() {
        super.init()
    }
    
    /**
     * update IK constraint for the given renderer
     */
    public class func updateIK(renderer: SCNSceneRenderer) {
        if let scene = renderer.scene {
            self.applyIKRecursive(scene.rootNode)
        }
    }
    
    /**
     * apply IK constraint recursively
     */
    public class func applyIKRecursive(_ node: SCNNode) {
        if let mmdNode = node as? MMDNode {
            mmdNode.updateIK()
        }
        
        for childNode in node.childNodes {
            self.applyIKRecursive(childNode)
        }
    }

    /**
     * apply IK constraint after animations are applied
     */
    public func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        MMDIKController.updateIK(renderer: renderer)
    }
}
