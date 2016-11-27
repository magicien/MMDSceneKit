//
//  MMDVMDReader.swift
//  MMDSceneKit
//
//  Created by magicien on 12/18/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

enum MMDMotionType {
    case Model
    case CameraOrLight
    case Camera
    case Light
}

#if os(watchOS)

class MMDVMDReader: MMDReader {
    // CAAnimation is not supported in watchOS
}

#else
class MMDVMDReader: MMDReader {
    // MARK: - property for VMD File
    private var workingAnimationGroup: CAAnimationGroup! = nil
    private var animationHash: [String: CAKeyframeAnimation]! = nil
    public var motionType: MMDMotionType! = nil
    
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
    static func getAnimation(_ data: Data, directoryPath: String! = "") -> CAAnimationGroup? {
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
        self.vmdMagic = String(getString(length: 30)!)
        self.motionName = String(getString(length: 20)!)
        
        if self.motionName == "カメラ・照明" {
            print("カメラ・照明用モーション")
            self.motionType = .CameraOrLight
        } else {
            self.motionType = .Model
        }
    }
    
    /**
     */
    private func readFrame() {
        self.frameCount = Int(getUnsignedInt())
        self.frameLength = 0
        let bytesPerFrame = 111
        
        if self.motionType == .CameraOrLight && self.frameCount > 0 {
            print("error: not model motion data has bone motion data")
            // skip data
            skip(bytesPerFrame * self.frameCount)
            return
        }
        
        for index in 0..<frameCount {
            let boneNameStr = getString(length: 15) as String?
            if boneNameStr == nil {
                print("motion(\(index)): skip because of broken bone name")
                // skip data
                skip(96)
                continue
            }
            let boneName = boneNameStr!
            
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
                
                frameIndex += 1
            }
            
            posXMotion!.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            posYMotion!.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            posZMotion!.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            rotMotion!.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            
            if(frameNo > frameLength) {
                frameLength = frameNo
            }
            
            //let position = SCNVector3.init(getFloat(), getFloat(), getFloat())
            let posX = NSNumber(value: getFloat())
            let posY = NSNumber(value: getFloat())
            let posZ = NSNumber(value: -getFloat())
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
            posXMotion!.timingFunctions!.insert(timingX, at: frameIndex)
            
            let timingY = CAMediaTimingFunction.init(controlPoints:
                interpolation[1],
                interpolation[5],
                interpolation[9],
                interpolation[13]
            )
            posYMotion!.timingFunctions!.insert(timingY, at: frameIndex)
            
            let timingZ = CAMediaTimingFunction.init(controlPoints:
                interpolation[2],
                interpolation[6],
                interpolation[10],
                interpolation[14]
            )
            posZMotion!.timingFunctions!.insert(timingZ, at: frameIndex)
            
            let timingRot = CAMediaTimingFunction.init(controlPoints:
                interpolation[3],
                interpolation[7],
                interpolation[11],
                interpolation[15]
            )
            rotMotion!.timingFunctions!.insert(timingRot, at: frameIndex)
            
            posXMotion!.values!.insert(posX, at: frameIndex)
            posYMotion!.values!.insert(posY, at: frameIndex)
            posZMotion!.values!.insert(posZ, at: frameIndex)
            rotMotion!.values!.insert(NSValue.init(scnVector4: rotate), at: frameIndex)
        }
        
    }
    
    /**
     */
    private func readFaceMotion() {
        let faceFrameCount = getUnsignedInt()
        //let timingFunc = CAMediaTimingFunction(controlPoints: 1, 0, 1, 1)
        let timingFunc = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        let bytesPerFrame = 23
        
        if self.motionType == .CameraOrLight && faceFrameCount > 0 {
            print("error: not model motion data has face motion data")
            // skip data
            skip(bytesPerFrame * Int(faceFrameCount))
            return
        }
        
        for _ in 0..<faceFrameCount {
            let name = String(getString(length: 15)!)
            let frameNo = Int(getUnsignedInt())
            let factor = NSNumber(value: getFloat())
            
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
                
                frameIndex += 1
            }
            
            animation!.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            animation!.values!.insert(factor, at:  frameIndex)
            animation!.timingFunctions!.insert(timingFunc, at: frameIndex)
        }
    }
    
    /**
     */
    private func createAnimations() {
        let duration = Double(self.frameLength) / 30.0
        print("bone frameLength: \(self.frameLength)")
        
        for (_, motion) in self.animationHash {
            for num in 0..<motion.keyTimes!.count {
                let keyTime = Float(motion.keyTimes![num]) / Float(self.frameLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
            
            motion.duration = duration
            motion.usesSceneTimeBase = false
            
            self.workingAnimationGroup.animations!.append(motion)
        }
        
        for (_, motion) in self.faceAnimationHash {
            print("faceAnimation: \(motion.keyPath!)")
            for num in 0..<motion.keyTimes!.count {
                let keyTime = Float(motion.keyTimes![num]) / Float(self.frameLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
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
        let cameraFrameCount = Int(getUnsignedInt())
        let bytesPerFrame = 61
        
        if cameraFrameCount == 0 {
            return
        }
        
        if self.motionType != .CameraOrLight {
            print("error: not camera motion has camera motion data")
            // skip data
            skip(bytesPerFrame * cameraFrameCount)
            return
        }
        self.motionType = .Camera

        // init values
        self.frameCount = cameraFrameCount
        self.frameLength = 0
        
        let distanceMotion = CAKeyframeAnimation(keyPath: "/\(MMD_CAMERA_NODE_NAME).translation.z")
        let posXMotion = CAKeyframeAnimation(keyPath: "transform.translation.x")
        let posYMotion = CAKeyframeAnimation(keyPath: "transform.translation.y")
        let posZMotion = CAKeyframeAnimation(keyPath: "transform.translation.z")
        //let rotMotion = CAKeyframeAnimation(keyPath: "transform.quaternion")
        let rotZMotion = CAKeyframeAnimation(keyPath: "eulerAngles.z")
        let rotXMotion = CAKeyframeAnimation(keyPath: "eulerAngles.x")
        let rotYMotion = CAKeyframeAnimation(keyPath: "/\(MMD_CAMERA_ROT_NODE_NAME).eulerAngles.y")
        let angleMotion = CAKeyframeAnimation(keyPath: "/\(MMD_CAMERA_NODE_NAME).camera.yFov")
        let persMotion = CAKeyframeAnimation(keyPath: "/\(MMD_CAMERA_NODE_NAME).camera.usesOrthographicProjection")
        
        distanceMotion.values = [AnyObject]()
        posXMotion.values = [AnyObject]()
        posYMotion.values = [AnyObject]()
        posZMotion.values = [AnyObject]()
        rotXMotion.values = [AnyObject]()
        rotYMotion.values = [AnyObject]()
        rotZMotion.values = [AnyObject]()
        angleMotion.values = [AnyObject]()
        persMotion.values = [AnyObject]()
        
        distanceMotion.keyTimes = [NSNumber]()
        posXMotion.keyTimes = [NSNumber]()
        posYMotion.keyTimes = [NSNumber]()
        posZMotion.keyTimes = [NSNumber]()
        rotXMotion.keyTimes = [NSNumber]()
        rotYMotion.keyTimes = [NSNumber]()
        rotZMotion.keyTimes = [NSNumber]()
        angleMotion.keyTimes = [NSNumber]()
        persMotion.keyTimes = [NSNumber]()
        
        distanceMotion.timingFunctions = [CAMediaTimingFunction]()
        posXMotion.timingFunctions = [CAMediaTimingFunction]()
        posYMotion.timingFunctions = [CAMediaTimingFunction]()
        posZMotion.timingFunctions = [CAMediaTimingFunction]()
        rotXMotion.timingFunctions = [CAMediaTimingFunction]()
        rotYMotion.timingFunctions = [CAMediaTimingFunction]()
        rotZMotion.timingFunctions = [CAMediaTimingFunction]()
        angleMotion.timingFunctions = [CAMediaTimingFunction]()
        //persMotion.timingFunctions = [CAMediaTimingFunction]()
        
        for index in 0..<self.frameCount {
            var frameIndex = 0
            let frameNo = Int(getUnsignedInt())
            
            // the frame number might not be sorted
            while frameIndex < posXMotion.keyTimes!.count {
                let k = Int(posXMotion.keyTimes![frameIndex])
                if(k > frameNo) {
                    break
                }
                
                frameIndex += 1
            }
            
            distanceMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            posXMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            posYMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            posZMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            rotXMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            rotYMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            rotZMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            angleMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            persMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            
            if(frameNo > self.frameLength) {
                self.frameLength = frameNo
            }
            
            let distance = NSNumber(value: -getFloat())
            let posX = NSNumber(value: getFloat())
            let posY = NSNumber(value: getFloat())
            let posZ = NSNumber(value: -getFloat())

            //var rotate = SCNQuaternion.init(-getFloat(), -getFloat(), getFloat(), getFloat())
            //normalize(&rotate)
            let rotX = -getFloat()
            let rotY = getFloat()
            let rotZ = -getFloat()

            /*
            let cosX = cos(rotX / 2)
            let cosY = cos(rotY / 2)
            let cosZ = cos(rotZ / 2)
            let sinX = sin(rotX / 2)
            let sinY = sin(rotY / 2)
            let sinZ = sin(rotZ / 2)

            var rotate = SCNQuaternion()
            rotate.x = OSFloat(sinX * cosY * cosZ + cosX * sinY * sinZ)
            rotate.y = OSFloat(cosX * sinY * cosZ - cosX * cosY * sinZ)
            rotate.z = OSFloat(cosX * cosY * sinZ - sinX * sinY * cosZ)
            rotate.w = OSFloat(cosX * cosY * cosZ + sinX * sinY * sinZ)
            normalize(&rotate)
            
            // FIXME: handling over 180 degrees
            if abs(rotX) > 360 || abs(rotY) > 360 || abs(rotZ) > 360 {
                // test
                rotate.w -= 2.0
            } else if abs(rotX) > 180 || abs(rotY) > 180 || abs(rotZ) > 180 {
                // test
            }
            */
            
            var interpolation = [Float]()
            for _ in 0..<24 {
                interpolation.append(Float(getUnsignedByte()) / 127.0)
            }
            print("[\(frameNo / 30)] \(interpolation)")
            
            let angle = NSNumber(value: getInt())
            let perspective = getUnsignedByte()
            let useOrtho = NSNumber(booleanLiteral: (perspective != 0))
            
            
            let timingX = CAMediaTimingFunction.init(controlPoints:
                interpolation[0],
                                                     interpolation[2],
                                                     interpolation[1],
                                                     interpolation[3]
            )
            posXMotion.timingFunctions!.insert(timingX, at: frameIndex)
            
            let timingY = CAMediaTimingFunction.init(controlPoints:
                interpolation[4],
                                                     interpolation[6],
                                                     interpolation[5],
                                                     interpolation[7]
            )
            posYMotion.timingFunctions!.insert(timingY, at: frameIndex)
            
            let timingZ = CAMediaTimingFunction.init(controlPoints:
                interpolation[8],
                                                     interpolation[10],
                                                     interpolation[9],
                                                     interpolation[11]
            )
            posZMotion.timingFunctions!.insert(timingZ, at: frameIndex)
            
            let timingRot = CAMediaTimingFunction.init(controlPoints:
                interpolation[12],
                                                       interpolation[14],
                                                       interpolation[13],
                                                       interpolation[15]
            )
            rotXMotion.timingFunctions!.insert(timingRot, at: frameIndex)
            rotYMotion.timingFunctions!.insert(timingRot, at: frameIndex)
            rotZMotion.timingFunctions!.insert(timingRot, at: frameIndex)
 
            let timingDistance = CAMediaTimingFunction.init(controlPoints:
                interpolation[16],
                                                       interpolation[18],
                                                       interpolation[17],
                                                       interpolation[19]
            )
            distanceMotion.timingFunctions!.insert(timingDistance, at: frameIndex)

            let timingAngle = CAMediaTimingFunction.init(controlPoints:
                interpolation[20],
                                                            interpolation[22],
                                                            interpolation[21],
                                                            interpolation[23]
            )
            angleMotion.timingFunctions!.insert(timingAngle, at: frameIndex)
 
            /*
            let timingX = CAMediaTimingFunction.init(controlPoints:
                interpolation[0],
                                                     interpolation[4],
                                                     interpolation[8],
                                                     interpolation[12]
            )
            posXMotion.timingFunctions!.insert(timingX, at: frameIndex)
            
            let timingY = CAMediaTimingFunction.init(controlPoints:
                interpolation[1],
                                                     interpolation[5],
                                                     interpolation[9],
                                                     interpolation[13]
            )
            posYMotion.timingFunctions!.insert(timingY, at: frameIndex)
            
            let timingZ = CAMediaTimingFunction.init(controlPoints:
                interpolation[2],
                                                     interpolation[6],
                                                     interpolation[10],
                                                     interpolation[14]
            )
            posZMotion.timingFunctions!.insert(timingZ, at: frameIndex)
            
            let timingRot = CAMediaTimingFunction.init(controlPoints:
                interpolation[3],
                                                       interpolation[7],
                                                       interpolation[11],
                                                       interpolation[15]
            )
            rotXMotion.timingFunctions!.insert(timingRot, at: frameIndex)
            rotYMotion.timingFunctions!.insert(timingRot, at: frameIndex)
            rotZMotion.timingFunctions!.insert(timingRot, at: frameIndex)
            
            let timingDistance = CAMediaTimingFunction.init(controlPoints:
                interpolation[16],
                                                            interpolation[18],
                                                            interpolation[17],
                                                            interpolation[19]
            )
            distanceMotion.timingFunctions!.insert(timingDistance, at: frameIndex)
            
            let timingAngle = CAMediaTimingFunction.init(controlPoints:
                interpolation[20],
                                                         interpolation[22],
                                                         interpolation[21],
                                                         interpolation[23]
            )
            angleMotion.timingFunctions!.insert(timingAngle, at: frameIndex)
            */
            
            distanceMotion.values!.insert(distance, at: frameIndex)
            posXMotion.values!.insert(posX, at: frameIndex)
            posYMotion.values!.insert(posY, at: frameIndex)
            posZMotion.values!.insert(posZ, at: frameIndex)
            //rotMotion.values!.insert(NSValue.init(scnVector4: rotate), at: frameIndex)
            rotXMotion.values!.insert(rotX, at: frameIndex)
            rotYMotion.values!.insert(rotY, at: frameIndex)
            rotZMotion.values!.insert(rotZ, at: frameIndex)
            angleMotion.values!.insert(angle, at: frameIndex)
            persMotion.values!.insert(useOrtho, at: frameIndex)
        }

        let duration = Double(self.frameLength) / 30.0
        print("camera frameLength: \(self.frameLength)")
        
        distanceMotion.duration = duration
        posXMotion.duration = duration
        posYMotion.duration = duration
        posZMotion.duration = duration
        rotXMotion.duration = duration
        rotYMotion.duration = duration
        rotZMotion.duration = duration
        angleMotion.duration = duration
        persMotion.duration = duration
        
        distanceMotion.usesSceneTimeBase = false
        posXMotion.usesSceneTimeBase = false
        posYMotion.usesSceneTimeBase = false
        posZMotion.usesSceneTimeBase = false
        rotXMotion.usesSceneTimeBase = false
        rotYMotion.usesSceneTimeBase = false
        rotZMotion.usesSceneTimeBase = false
        angleMotion.usesSceneTimeBase = false
        persMotion.usesSceneTimeBase = false
        
        self.workingAnimationGroup.animations!.append(distanceMotion)
        self.workingAnimationGroup.animations!.append(posXMotion)
        self.workingAnimationGroup.animations!.append(posYMotion)
        self.workingAnimationGroup.animations!.append(posZMotion)
        self.workingAnimationGroup.animations!.append(rotXMotion)
        self.workingAnimationGroup.animations!.append(rotYMotion)
        self.workingAnimationGroup.animations!.append(rotZMotion)
        self.workingAnimationGroup.animations!.append(angleMotion)
        self.workingAnimationGroup.animations!.append(persMotion)
        self.workingAnimationGroup.duration = duration
        self.workingAnimationGroup.usesSceneTimeBase = false
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

#endif
