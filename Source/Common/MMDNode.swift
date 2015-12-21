//
//  MMDNode.swift
//  MMDSceneKit
//
//  Created by magicien on 12/9/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

public enum MMDNodeType {
    case ROTATE
    case ROTATE_TRANSLATE
    case IK
    case UNKNOWN
    case IK_CHILD
    case ROTATE_CHILD
    case IK_TARGET
    case HIDDEN
    case TWIST
    case ROLL
}

public class MMDNode: SCNNode {
    public internal(set) var physicsBehaviors: [SCNPhysicsBehavior]! = []
    public internal(set) var type: MMDNodeType = .UNKNOWN
    // FIXME: internal variant
    public var ikTargetBone: MMDNode? = nil
    //public var ikConstraint: SCNIKConstraint? = nil
    internal var ikConstraint: MMDIKConstraint? = nil
    
    override public func valueForUndefinedKey(key: String) -> AnyObject? {
        if key.hasPrefix("/") {
            let searchKey = (key as NSString).substringFromIndex(1)
            if let node = self.childNodeWithName(searchKey, recursively: true) {
                return node
            }
            
        }
        
        return super.valueForUndefinedKey(key)
    }
    
    override public func addAnimation(animation: CAAnimation, forKey key: String?) {
        let geometryNode = self.childNodeWithName("Geometry", recursively: true)
        
        // FIXME: clone values
        if let group = animation as? CAAnimationGroup {
            
            if let animations = group.animations {
                for anim in animations {
                    if let keyAnim = anim as? CAKeyframeAnimation {
                        let boneNameKey = keyAnim.keyPath!.componentsSeparatedByString(".")[0]
                        let boneName = (boneNameKey as NSString).substringFromIndex(1)
                        let bone = self.childNodeWithName(boneName, recursively: true)
                        
                        if boneNameKey == "morpher" {
                            if keyAnim.keyPath!.hasPrefix("morpher.weights.") {
                                print("morpher Animation - \(keyAnim.keyPath!)")
                                let faceName = (keyAnim.keyPath! as NSString).substringFromIndex(16)
                                var faceIndex = -1
                                
                                // search face name from geometry node
                                for index in 0..<geometryNode!.morpher!.targets.count {
                                    if geometryNode!.morpher!.targets[index].name == faceName {
                                        faceIndex = index
                                        break
                                    }
                                }

                                if faceIndex >= 0 {
                                    let newKeyPath: String! = "/Geometry.morpher.weights[\(faceIndex)]"
                                    keyAnim.keyPath = newKeyPath
                                    

                                    //print("set keyPath: \(keyAnim.keyPath!): \(faceName)")
                                    
                                    for index in 0..<keyAnim.values!.count {
                                        let val = keyAnim.values![index]
                                        let tim = keyAnim.keyTimes![index]
                                        
                                        //print("  \(tim): \(val)")
                                    }
                                }else{
                                    keyAnim.keyPath = "//"
                                }
                            }
                        } else if bone != nil {
                            if keyAnim.keyPath!.hasSuffix(".translation.x") {
                                // FIXME: clone values
                            
                                for index in 0..<keyAnim.values!.count {
                                    let origValue = keyAnim.values![index] as! Float
                                    let newValue = origValue + Float(bone!.position.x)
                                    keyAnim.values![index] = newValue
                                }
                            }else if keyAnim.keyPath!.hasSuffix(".translation.y") {
                                for index in 0..<keyAnim.values!.count {
                                    let origValue = keyAnim.values![index] as! Float
                                    let newValue = origValue + Float(bone!.position.y)
                                    keyAnim.values![index] = newValue
                                }
                            }else if keyAnim.keyPath!.hasSuffix(".translation.z") {
                                for index in 0..<keyAnim.values!.count {
                                    let origValue = keyAnim.values![index] as! Float
                                    let newValue = origValue + Float(bone!.position.z)
                                    keyAnim.values![index] = newValue
                                }
                            }
                        }
                    }else{
                    }
                }
            }
        }
        super.addAnimation(animation, forKey: key)
    }    
}
