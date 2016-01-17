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

class GameViewController: NSViewController, SCNSceneRendererDelegate {
    
    @IBOutlet weak var gameView: GameView!
    
    override func awakeFromNib(){
        // create a new scene
        scene = SCNScene()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.automaticallyAdjustsZRange = true
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 10, z: 40)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 100, z: 10)
        lightNode.castsShadow = true
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = NSColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)

        let modelPath = NSBundle.mainBundle().pathForResource("art.scnassets/miku", ofType: ".pmd")
        let modelSceneSource = MMDSceneSource(path: modelPath!)
        let modelNode = modelSceneSource!.modelNodes().first!
        modelNode.position = SCNVector3Make(0, 50.0, 0.0)
        scene.rootNode.addChildNode(modelNode)
        
        let xPath = NSBundle.mainBundle().pathForResource("art.scnassets/ゲキド街v3.0", ofType: ".x")
        let xSceneSource = MMDSceneSource(path: xPath!)
        let xNode = xSceneSource!.modelNodes().first!
        xNode.scale = SCNVector3Make(10.0, 10.0, 10.0)
        scene.rootNode.addChildNode(xNode)
        
        let behaviors = modelNode.physicsBehaviors
        for behavior in behaviors {
            scene.physicsWorld.addBehavior(behavior)
        }

        // animate the 3d object
        let motionPath = NSBundle.mainBundle().pathForResource("art.scnassets/happysyn", ofType: ".vmd")
        let motionSceneSource = MMDSceneSource(path: motionPath!)
        //let animations = motionSceneSource?.animations()
        let motion = motionSceneSource?.animations().first?.1
        motion!.repeatCount = Float.infinity
        modelNode.addAnimation(motion!, forKey: "happysyn")
                
        self.gameView!.delegate = self
        
        // set the scene to the view
        self.gameView!.scene = scene
        
        // allows the user to manipulate the camera
        self.gameView!.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        self.gameView!.showsStatistics = true
        
        // configure the view
        self.gameView!.backgroundColor = NSColor.blackColor()
    }

    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        //print("updateAtTime")
    }
    func renderer(renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: NSTimeInterval) {
        //print("didApplyAnimationsAtTime")
        //applyIKRecursive(scene.rootNode)
        
        /*
        for node in scene.rootNode.childNodes {
            if let mmdNode = node as? MMDNode {
                print("MMDNode: \(mmdNode)")
                if mmdNode.ikTargetBone != nil {
                    print("IK: \(mmdNode.ikTargetBone)")
                    let mat = mmdNode.worldTransform
                    let x = mat.m11 + mat.m21 + mat.m31 + mat.m41
                    let y = mat.m12 + mat.m22 + mat.m32 + mat.m42
                    let z = mat.m13 + mat.m23 + mat.m33 + mat.m43
                    mmdNode.ikTargetBone!.ikConstraint!.targetPosition.x = x
                    mmdNode.ikTargetBone!.ikConstraint!.targetPosition.y = y
                    mmdNode.ikTargetBone!.ikConstraint!.targetPosition.z = z
                }
            }
        }
        */
        

        applyIKRecursive(scene.rootNode)
        
        for node in scene.rootNode.childNodes {
            if let mmdNode = node as? MMDNode {
                //mmdNode.updateFace()
            }
        }
    }

    func applyIKRecursive(node: SCNNode) {
        if let mmdNode = node as? MMDNode {
            /*
            if mmdNode.ikTargetBone != nil {
                //print("IK: \(mmdNode.ikTargetBone)")
                //let mat = mmdNode.worldTransform
                //let x = mat.m11 + mat.m21 + mat.m31 + mat.m41
                //let y = mat.m12 + mat.m22 + mat.m32 + mat.m42
                //let z = mat.m13 + mat.m23 + mat.m33 + mat.m43

                //mmdNode.ikTargetBone!.ikConstraint!.targetPosition.x = mat.m41
                //mmdNode.ikTargetBone!.ikConstraint!.targetPosition.y = mat.m42
                //mmdNode.ikTargetBone!.ikConstraint!.targetPosition.z = mat.m43
            }*/
            mmdNode.updateIK()
        }
        
        for childNode in node.childNodes {
            applyIKRecursive(childNode)
        }
    }
    
    func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        //print("didSimulatePhysicsAtTime")
    }
    func renderer(renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        //print("willRenderScene")
    }
    func renderer(renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: NSTimeInterval) {
        //print("didRenderScene")
    }
}
