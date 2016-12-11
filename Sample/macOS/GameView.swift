//
//  GameView.swift
//  MMDSceneKitSample_macOS
//
//  Created by magicien on 12/10/15.
//  Copyright (c) 2015 DarkHorse. All rights reserved.
//

import SceneKit
import MMDSceneKit_macOS

class GameView: SCNView {
    
    override func mouseDown(with theEvent: NSEvent) {
        return
        let materials = mikuNode.materialArray!
        for index in 0..<materials.count {
            let material = materials[index]
        }
        return
        /* Called when a mouse click occurs */
        
        // get morpher
        let geometryNode = scene!.rootNode.childNode(withName: "Geometry", recursively: true)
        let morpher = geometryNode!.morpher
        
        let childNodes = scene!.rootNode.childNodes
        
        // check what nodes are clicked
        let p = self.convert(theEvent.locationInWindow, from: nil)
        let hitResults = self.hitTest(p, options: nil)
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            //SCNTransaction.setAnimationDuration(0.5)
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            //SCNTransaction.setCompletionBlock() {
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                //SCNTransaction.setAnimationDuration(0.5)
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = NSColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = NSColor.red
            
            SCNTransaction.commit()
        }
        
        super.mouseDown(with: theEvent)
    }

}
