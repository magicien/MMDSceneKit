//
//  MMDVMDReader.swift
//  MMDSceneKit
//
//  Created by magicien on 12/18/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

class MMDVMDReader: MMDReader {
    // MARK: - property for VMD File
    private var workingAnimationGroup: CAAnimationGroup! = nil
    private var animationHash: [String: CAKeyframeAnimation]! = nil
    
    // MARK: VMD header data
    private var vmdMagic: String! = ""
    private var motionName: String! = ""
    
    // MARK: frame data
    private var frameCount = 0
    private var frameLength = 0
    
    // MARK: face motion data
    private var faceAnimationHash: [String: CAKeyframeAnimation]! = nil
    
    // MARK: camera motion data
    
    // MARK: light motion data
    
    // MARK: shadow data
    
    // MARK: visibility and IK data
    
    /**
    */
    static func getAnimation(data: NSData, directoryPath: String! = "") -> CAAnimationGroup? {
        let reader = MMDVMDReader(data: data, directoryPath: directoryPath)
        let animation = reader.loadVMDFile()
        
        return animation
    }
    
    // MARK: - Loading VMD File
    
    /**
    */
    private func loadVMDFile() -> CAAnimationGroup? {
        self.workingAnimationGroup = CAAnimationGroup()
        self.workingAnimationGroup.animations = [CAAnimation]()
        
        self.animationHash = [String: CAKeyframeAnimation]()
        self.faceAnimationHash = [String: CAKeyframeAnimation]()
        
        self.readVMDHeader()
        self.readFrame()
        self.readFaceMotion()
        self.createAnimations()
        
        // FIXME: avoid key conflict
        //self.workingNode.addAnimation(self.workingAnimationGroup, forKey: "animation")
        //self.workingScene.rootNode.addChildNode(self.workingNode)
        
        if (self.pos >= self.length) {
            return self.workingAnimationGroup
        }
        
        self.readCameraMotion()
        self.readLightMotion()
        
        if (self.pos >= self.length) {
            return self.workingAnimationGroup
        }
        
        self.readShadow()
        
        if (self.pos >= self.length) {
            return self.workingAnimationGroup
        }
        
        self.readVisibilityAndIK()
        
        return self.workingAnimationGroup
    }
    
    /**
     */
    private func readVMDHeader() {
        self.vmdMagic = String(getString(30)!)
        self.motionName = String(getString(20)!)
        
        if self.motionName == "カメラ・照明" {
            print("カメラ・照明用モーション")
        }
    }
    
    /**
     */
    private func readFrame() {
        self.frameCount = Int(getUnsignedInt())
        self.frameLength = 0
        
        for _ in 0..<frameCount {
            let boneName: String! = getString(15) as! String
            
            var posXMotion = self.animationHash["posX:\(boneName)"]
            var posYMotion = self.animationHash["posY:\(boneName)"]
            var posZMotion = self.animationHash["posZ:\(boneName)"]
            var rotMotion = self.animationHash["rot:\(boneName)"]
            
            if (posXMotion == nil) {
                //if (targetBone!.name!.hasSuffix("IK")) {
                //posXMotion = CAKeyframeAnimation(keyPath: "
                //} else {
                posXMotion = CAKeyframeAnimation(keyPath: "/\(boneName).transform.translation.x")
                posYMotion = CAKeyframeAnimation(keyPath: "/\(boneName).transform.translation.y")
                posZMotion = CAKeyframeAnimation(keyPath: "/\(boneName).transform.translation.z")
                //posXMotion = CAKeyframeAnimation(keyPath: "/\(boneName).position.x")
                //posYMotion = CAKeyframeAnimation(keyPath: "/\(boneName).position.y")
                //posZMotion = CAKeyframeAnimation(keyPath: "/\(boneName).position.z")
                rotMotion = CAKeyframeAnimation(keyPath: "/\(boneName).transform.quaternion")
                //}
                
                posXMotion!.values = [AnyObject]()
                posYMotion!.values = [AnyObject]()
                posZMotion!.values = [AnyObject]()
                rotMotion!.values = [AnyObject]()
                
                posXMotion!.keyTimes = [NSNumber]()
                posYMotion!.keyTimes = [NSNumber]()
                posZMotion!.keyTimes = [NSNumber]()
                rotMotion!.keyTimes = [NSNumber]()
                
                posXMotion!.timingFunctions = [CAMediaTimingFunction]()
                posYMotion!.timingFunctions = [CAMediaTimingFunction]()
                posZMotion!.timingFunctions = [CAMediaTimingFunction]()
                rotMotion!.timingFunctions = [CAMediaTimingFunction]()
                
                self.animationHash["posX:\(boneName)"] = posXMotion
                self.animationHash["posY:\(boneName)"] = posYMotion
                self.animationHash["posZ:\(boneName)"] = posZMotion
                self.animationHash["rot:\(boneName)"] = rotMotion
            }
            
            var frameIndex = 0
            let frameNo = Int(getUnsignedInt())
            
            //for index in 0...posXMotion!.keyTimes!.count {
            while frameIndex < posXMotion!.keyTimes!.count {
                let k = Int(posXMotion!.keyTimes![frameIndex])
                if(k > frameNo) {
                    break
                }
                
                frameIndex++
            }
            
            posXMotion!.keyTimes!.insert(Float(frameNo), atIndex: frameIndex)
            posYMotion!.keyTimes!.insert(Float(frameNo), atIndex: frameIndex)
            posZMotion!.keyTimes!.insert(Float(frameNo), atIndex: frameIndex)
            rotMotion!.keyTimes!.insert(Float(frameNo), atIndex: frameIndex)
            
            if(frameNo > frameLength) {
                frameLength = frameNo
            }
            
            //let position = SCNVector3.init(getFloat(), getFloat(), getFloat())
            let posX = NSNumber(float: getFloat())
            let posY = NSNumber(float: getFloat())
            let posZ = NSNumber(float: -getFloat())
            var rotate = SCNQuaternion.init(-getFloat(), -getFloat(), getFloat(), getFloat())
            
            normalize(&rotate)
            
            var interpolation = [Float]()
            for _ in 0..<64 {
                interpolation.append(Float(getUnsignedByte()) / 127.0)
            }
            
            let timingX = CAMediaTimingFunction.init(controlPoints:
                interpolation[0],
                interpolation[4],
                interpolation[8],
                interpolation[12]
            )
            posXMotion!.timingFunctions!.insert(timingX, atIndex: frameIndex)
            
            let timingY = CAMediaTimingFunction.init(controlPoints:
                interpolation[1],
                interpolation[5],
                interpolation[9],
                interpolation[13]
            )
            posYMotion!.timingFunctions!.insert(timingY, atIndex: frameIndex)
            
            let timingZ = CAMediaTimingFunction.init(controlPoints:
                interpolation[2],
                interpolation[6],
                interpolation[10],
                interpolation[14]
            )
            posZMotion!.timingFunctions!.insert(timingZ, atIndex: frameIndex)
            
            let timingRot = CAMediaTimingFunction.init(controlPoints:
                interpolation[3],
                interpolation[7],
                interpolation[11],
                interpolation[15]
            )
            rotMotion!.timingFunctions!.insert(timingRot, atIndex: frameIndex)
            
            posXMotion!.values!.insert(posX, atIndex: frameIndex)
            posYMotion!.values!.insert(posY, atIndex: frameIndex)
            posZMotion!.values!.insert(posZ, atIndex: frameIndex)
            rotMotion!.values!.insert(NSValue.init(SCNVector4: rotate), atIndex: frameIndex)
        }
        
    }
    
    /**
     */
    private func readFaceMotion() {
        let faceFrameCount = getUnsignedInt()
        //let timingFunc = CAMediaTimingFunction(controlPoints: 1, 0, 1, 1)
        let timingFunc = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        for _ in 0..<faceFrameCount {
            let name = String(getString(15)!)
            let frameNo = Int(getUnsignedInt())
            let factor = NSNumber(float: getFloat())
            
            let keyPath: String! = "morpher.weights.\(name)"
            var animation = self.faceAnimationHash[name]
            
            if animation == nil {
                animation = CAKeyframeAnimation(keyPath: keyPath)
                animation!.values = [AnyObject]()
                animation!.keyTimes = [NSNumber]()
                animation!.timingFunctions = [CAMediaTimingFunction]()
                
                self.faceAnimationHash[name] = animation
            }
            
            var frameIndex = 0
            while frameIndex < animation!.keyTimes!.count {
                let k = Int(animation!.keyTimes![frameIndex])
                if(k > frameNo) {
                    break
                }
                
                frameIndex++
            }
            
            animation!.keyTimes!.insert(frameNo, atIndex: frameIndex)
            animation!.values!.insert(factor, atIndex:  frameIndex)
            animation!.timingFunctions!.insert(timingFunc, atIndex: frameIndex)
        }
    }
    
    /**
     */
    private func createAnimations() {
        let duration = Double(self.frameLength) / 30.0
        print("frameLength: \(self.frameLength)")
        
        for (_, motion) in self.animationHash {
            for num in 0..<motion.keyTimes!.count {
                let keyTime = Float(motion.keyTimes![num]) / Float(self.frameLength)
                motion.keyTimes![num] = NSNumber(float: keyTime)
            }
            
            motion.duration = duration
            motion.usesSceneTimeBase = false
            
            self.workingAnimationGroup.animations!.append(motion)
        }
        
        for (_, motion) in self.faceAnimationHash {
            print("faceAnimation: \(motion.keyPath!)")
            for num in 0..<motion.keyTimes!.count {
                let keyTime = Float(motion.keyTimes![num]) / Float(self.frameLength)
                motion.keyTimes![num] = NSNumber(float: keyTime)
            }
            
            motion.duration = duration
            motion.usesSceneTimeBase = false
            
            self.workingAnimationGroup.animations!.append(motion)
        }
        
        /*
        let motion = CAKeyframeAnimation(keyPath: "faceAnimation")
        let timing = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionLinear)
        motion.values = [NSNumber(float: 0), NSNumber(float: 1)]
        motion.keyTimes = [NSNumber(float: 0), NSNumber(float: 1)]
        motion.timingFunctions = [timing, timing]
        motion.duration = duration
        motion.usesSceneTimeBase = false
        self.workingAnimationGroup.animations!.append(motion)
        */
        
        self.workingAnimationGroup.duration = duration
        self.workingAnimationGroup.usesSceneTimeBase = false
    }
    
    /**
     */
    private func readCameraMotion() {
        
    }
    
    /**
     */
    private func readLightMotion() {
    }
    
    /**
     */
    private func readShadow() {
    }
    
    /**
     */
    private func readVisibilityAndIK() {
    }

}