//
//  MMDNode.swift
//  MMDSceneKit
//
//  Created by magicien on 12/9/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

public class MMDNode: SCNNode {
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
        // FIXME: clone values
        if let group = animation as? CAAnimationGroup {
            /*
            let newAnimation = CAAnimationGroup()
            
            newAnimation.removedOnCompletion = group.removedOnCompletion
            newAnimation.timingFunction = group.timingFunction
            newAnimation.delegate = group.delegate
            newAnimation.usesSceneTimeBase = group.usesSceneTimeBase
            newAnimation.fadeInDuration = group.fadeInDuration
            newAnimation.fadeOutDuration = group.fadeOutDuration
            newAnimation.animationEvents = group.animationEvents
            newAnimation.animations = [CAAnimation]()
            */
            
            if let animations = group.animations {
                for anim in animations {
                    if let keyAnim = anim as? CAKeyframeAnimation {
                        let boneNameKey = keyAnim.keyPath!.componentsSeparatedByString(".")[0]
                        let boneName = (boneNameKey as NSString).substringFromIndex(1)
                        let bone = self.childNodeWithName(boneName, recursively: true)
                        if bone != nil {
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
