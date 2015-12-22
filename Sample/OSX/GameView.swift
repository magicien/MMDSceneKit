//
//  GameView.swift
//  MMDSceneKitSample_OSX
//
//  Created by magicien on 12/10/15.
//  Copyright (c) 2015 DarkHorse. All rights reserved.
//

import SceneKit
import MMDSceneKit_OSX

class GameView: SCNView {
    
    override func mouseDown(theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        
        // get morpher
        let geometryNode = scene!.rootNode.childNodeWithName("Geometry", recursively: true)
        let morpher = geometryNode!.morpher
        
        let childNodes = scene!.rootNode.childNodes

        /*
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(0.5)

        SCNTransaction.setCompletionBlock() {
            SCNTransaction.begin()
            SCNTransaction.setAnimationDuration(0.5)
            
            for node in childNodes {
                if let mmdNode = node as? MMDNode {
                    if mmdNode.ikTargetBone != nil {
                        for constraint in mmdNode.ikTargetBone!.constraints! {
                            if let ikConstraint = constraint as? SCNIKConstraint {
                                ikConstraint.targetPosition = SCNVector3(0, 0, 0)
                            }
                        }
                        //info("IK-2: \(mmdNode.ikTargetBone)")
                    }
                }
            }
            
            SCNTransaction.commit()
        }
*/

#if false
        for node in childNodes {
            if let mmdNode = node as? MMDNode {
                if mmdNode.ikTargetBone != nil {
                    //print("IK: \(mmdNode.ikTargetBone)")
                    /*
                    let mat = mmdNode.worldTransform
                    let x = mat.m11 + mat.m21 + mat.m31 + mat.m41
                    let y = mat.m12 + mat.m22 + mat.m32 + mat.m42
                    let z = mat.m13 + mat.m23 + mat.m33 + mat.m43
                    mmdNode.ikTargetBone!.ikConstraint!.targetPosition.x = x
                    mmdNode.ikTargetBone!.ikConstraint!.targetPosition.y = y
                    mmdNode.ikTargetBone!.ikConstraint!.targetPosition.z = z
                    */
                    for constraint in mmdNode.ikTargetBone!.constraints! {
                        if let ikConstraint = constraint as? SCNIKConstraint {
                            ikConstraint.targetPosition = SCNVector3(0, 100, 0)
                        }
                    }
                    //mmdNode.ikTargetBone!.ikConstraint!.targetPosition = SCNVector3(0, 100, 0)
                }
            }
        }
        SCNTransaction.commit()
#endif
        
        
        // check what nodes are clicked
        let p = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        let hitResults = self.hitTest(p, options: nil)
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.setAnimationDuration(0.5)
            
            // on completion - unhighlight
            SCNTransaction.setCompletionBlock() {
                SCNTransaction.begin()
                SCNTransaction.setAnimationDuration(0.5)
                
                material.emission.contents = NSColor.blackColor()
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = NSColor.redColor()
            
            SCNTransaction.commit()
        }
        
        super.mouseDown(theEvent)
    }

}
