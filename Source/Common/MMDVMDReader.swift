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
    public var fps = 30.0
    
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
            
            var frameIndex = posXMotion!.keyTimes!.count - 1
            let frameNo = Int(getUnsignedInt())
            
            while frameIndex >= 0 {
                let k = Int(posXMotion!.keyTimes![frameIndex])
                if(k < frameNo) {
                    break
                }
                
                frameIndex -= 1
            }
            frameIndex += 1
            
            posXMotion!.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            posYMotion!.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            posZMotion!.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            rotMotion!.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            
            if(frameNo > frameLength) {
                frameLength = frameNo
            }
            
            let posX = NSNumber(value: getFloat())
            let posY = NSNumber(value: getFloat())
            let posZ = NSNumber(value: -getFloat())
            var rotate = SCNQuaternion(-getFloat(), -getFloat(), getFloat(), getFloat())
            
            normalize(&rotate)
            
            var interpolation = [Float]()
            for _ in 0..<64 {
                interpolation.append(Float(getUnsignedByte()) / 127.0)
            }
            
            let timingX = CAMediaTimingFunction(controlPoints:
                interpolation[0],
                interpolation[4],
                interpolation[8],
                interpolation[12]
            )
            posXMotion!.timingFunctions!.insert(timingX, at: frameIndex)
            
            let timingY = CAMediaTimingFunction(controlPoints:
                interpolation[1],
                interpolation[5],
                interpolation[9],
                interpolation[13]
            )
            posYMotion!.timingFunctions!.insert(timingY, at: frameIndex)
            
            let timingZ = CAMediaTimingFunction(controlPoints:
                interpolation[2],
                interpolation[6],
                interpolation[10],
                interpolation[14]
            )
            posZMotion!.timingFunctions!.insert(timingZ, at: frameIndex)
            
            let timingRot = CAMediaTimingFunction(controlPoints:
                interpolation[3],
                interpolation[7],
                interpolation[11],
                interpolation[15]
            )
            rotMotion!.timingFunctions!.insert(timingRot, at: frameIndex)
            
            posXMotion!.values!.insert(posX, at: frameIndex)
            posYMotion!.values!.insert(posY, at: frameIndex)
            posZMotion!.values!.insert(posZ, at: frameIndex)
            rotMotion!.values!.insert(NSValue(scnVector4: rotate), at: frameIndex)
        }
        
    }
    
    /**
     */
    private func readFaceMotion() {
        let faceFrameCount = getUnsignedInt()
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
            
            var frameIndex = animation!.keyTimes!.count - 1
            while frameIndex >= 0 {
                let k = Int(animation!.keyTimes![frameIndex])
                if(k < frameNo) {
                    break
                }
                
                frameIndex -= 1
            }
            frameIndex += 1
            
            animation!.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            animation!.values!.insert(factor, at:  frameIndex)
            animation!.timingFunctions!.insert(timingFunc, at: frameIndex)
        }
    }
    
    /**
     */
    private func createAnimations() {
        let duration = Double(self.frameLength) / self.fps
        print("bone frameLength: \(self.frameLength)")
        
        for (_, motion) in self.animationHash {
            let motionLength = Double(motion.keyTimes!.last!)
            for num in 0..<motion.keyTimes!.count {
                let keyTime = Float(motion.keyTimes![num]) / Float(motionLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
            
            motion.duration = motionLength / self.fps
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards
            
            self.workingAnimationGroup.animations!.append(motion)
        }
        
        for (_, motion) in self.faceAnimationHash {
            print("faceAnimation: \(motion.keyPath!)")
            let motionLength = Double(motion.keyTimes!.last!)

            for num in 0..<motion.keyTimes!.count {
                let keyTime = Float(motion.keyTimes![num]) / Float(motionLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
            
            motion.duration = motionLength / self.fps
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards
            
            self.workingAnimationGroup.animations!.append(motion)
        }
        
        /*
        let motion = CAKeyframeAnimation(keyPath: "faceAnimation")
        let timing = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        motion.values = [NSNumber(float: 0), NSNumber(float: 1)]
        motion.keyTimes = [NSNumber(float: 0), NSNumber(float: 1)]
        motion.timingFunctions = [timing, timing]
        motion.duration = duration
        motion.usesSceneTimeBase = false
        self.workingAnimationGroup.animations!.append(motion)
        */
        
        self.workingAnimationGroup.duration = duration
        self.workingAnimationGroup.usesSceneTimeBase = false
        self.workingAnimationGroup.isRemovedOnCompletion = false
        self.workingAnimationGroup.fillMode = kCAFillModeForwards
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
        let rotZMotion = CAKeyframeAnimation(keyPath: "/\(MMD_CAMERA_ROTZ_NODE_NAME).eulerAngles.z")
        let rotXMotion = CAKeyframeAnimation(keyPath: "/\(MMD_CAMERA_ROTX_NODE_NAME).eulerAngles.x")
        let rotYMotion = CAKeyframeAnimation(keyPath: "/\(MMD_CAMERA_ROTY_NODE_NAME).eulerAngles.y")
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
        
        for _ in 0..<self.frameCount {
            var frameIndex = distanceMotion.keyTimes!.count - 1
            let frameNo = Int(getUnsignedInt())
            
            // the frame number might not be sorted
            while frameIndex >= 0 {
                let k = Int(distanceMotion.keyTimes![frameIndex])
                if(k < frameNo) {
                    break
                }
                
                frameIndex -= 1
            }
            frameIndex += 1
            
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

            let rotX = getFloat()
            let rotY = getFloat()
            let rotZ = -getFloat()
            
            var interpolation = [Float]()
            for _ in 0..<24 {
                interpolation.append(Float(getUnsignedByte()) / 127.0)
            }
            print("[\(frameNo / 30)] \(interpolation)")
            
            let angle = NSNumber(value: getInt())
            let perspective = getUnsignedByte()
            let useOrtho = NSNumber(booleanLiteral: (perspective != 0))
            
            
            let timingX = CAMediaTimingFunction(controlPoints:
                interpolation[0],
                                                     interpolation[2],
                                                     interpolation[1],
                                                     interpolation[3]
            )
            posXMotion.timingFunctions!.insert(timingX, at: frameIndex)
            
            let timingY = CAMediaTimingFunction(controlPoints:
                interpolation[4],
                                                     interpolation[6],
                                                     interpolation[5],
                                                     interpolation[7]
            )
            posYMotion.timingFunctions!.insert(timingY, at: frameIndex)
            
            let timingZ = CAMediaTimingFunction(controlPoints:
                interpolation[8],
                                                     interpolation[10],
                                                     interpolation[9],
                                                     interpolation[11]
            )
            posZMotion.timingFunctions!.insert(timingZ, at: frameIndex)
            
            let timingRot = CAMediaTimingFunction(controlPoints:
                interpolation[12],
                                                       interpolation[14],
                                                       interpolation[13],
                                                       interpolation[15]
            )
            rotXMotion.timingFunctions!.insert(timingRot, at: frameIndex)
            rotYMotion.timingFunctions!.insert(timingRot, at: frameIndex)
            rotZMotion.timingFunctions!.insert(timingRot, at: frameIndex)
 
            let timingDistance = CAMediaTimingFunction(controlPoints:
                interpolation[16],
                                                       interpolation[18],
                                                       interpolation[17],
                                                       interpolation[19]
            )
            distanceMotion.timingFunctions!.insert(timingDistance, at: frameIndex)

            let timingAngle = CAMediaTimingFunction(controlPoints:
                interpolation[20],
                                                            interpolation[22],
                                                            interpolation[21],
                                                            interpolation[23]
            )
            angleMotion.timingFunctions!.insert(timingAngle, at: frameIndex)
 
            distanceMotion.values!.insert(distance, at: frameIndex)
            posXMotion.values!.insert(posX, at: frameIndex)
            posYMotion.values!.insert(posY, at: frameIndex)
            posZMotion.values!.insert(posZ, at: frameIndex)
            rotXMotion.values!.insert(rotX, at: frameIndex)
            rotYMotion.values!.insert(rotY, at: frameIndex)
            rotZMotion.values!.insert(rotZ, at: frameIndex)
            angleMotion.values!.insert(angle, at: frameIndex)
            persMotion.values!.insert(useOrtho, at: frameIndex)
        }

        let duration = Double(self.frameLength) / self.fps
        print("camera frameLength: \(self.frameLength)")
        
        for motion in [distanceMotion, posXMotion, posYMotion, posZMotion, rotXMotion, rotYMotion, rotZMotion, angleMotion, persMotion] {
            let motionLength = Double(motion.keyTimes!.last!)
            motion.duration = motionLength / self.fps
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards
            
            for num in 0..<motion.keyTimes!.count {
                let keyTime = Float(motion.keyTimes![num]) / Float(motionLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
            
            self.workingAnimationGroup.animations!.append(motion)
        }

        self.workingAnimationGroup.duration = duration
        self.workingAnimationGroup.usesSceneTimeBase = false
        self.workingAnimationGroup.isRemovedOnCompletion = false
        self.workingAnimationGroup.fillMode = kCAFillModeForwards
    }
    
    /**
     */
    private func readLightMotion() {
        let lightFrameCount = Int(getUnsignedInt())
        let bytesPerFrame = 28
        
        if lightFrameCount == 0 {
            return
        }
        
        if self.motionType != .CameraOrLight {
            print("error: not light motion has light motion data")
            // skip data
            skip(bytesPerFrame * lightFrameCount)
            return
        }
        self.motionType = .Light
        
        // init values
        self.frameCount = lightFrameCount
        self.frameLength = 0
        
        let colorMotion = CAKeyframeAnimation(keyPath: "light.color")
        let directionMotion = CAKeyframeAnimation(keyPath: "transform.quaternion")
        
        colorMotion.values = [AnyObject]()
        directionMotion.values = [AnyObject]()
        
        colorMotion.keyTimes = [NSNumber]()
        directionMotion.keyTimes = [NSNumber]()
        
        for _ in 0..<self.frameCount {
            var frameIndex = colorMotion.keyTimes!.count - 1
            let frameNo = Int(getUnsignedInt())
            
            // the frame number might not be sorted
            while frameIndex >= 0 {
                let k = Int(colorMotion.keyTimes![frameIndex])
                if(k < frameNo) {
                    break
                }
                
                frameIndex -= 1
            }
            frameIndex += 1
            
            colorMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            directionMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            
            if(frameNo > self.frameLength) {
                self.frameLength = frameNo
            }
            
            #if os(iOS) || os(tvOS) || os(watchOS)
                let color = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: 1.0)
            #elseif os(macOS)
                let color = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: 1.0)
            #endif
            colorMotion.values!.insert(color, at: frameIndex)
            
            
            let rotX = getFloat()
            let rotY = getFloat()
            let rotZ = getFloat()
            
            let cosX = cos(rotX / 2)
            let cosY = cos(rotY / 2)
            let cosZ = cos(rotZ / 2)
            let sinX = sin(rotX / 2)
            let sinY = sin(rotY / 2)
            let sinZ = sin(rotZ / 2)
            
            var quat = SCNQuaternion()
            quat.x = OSFloat(sinX * cosY * cosZ + cosX * sinY * sinZ)
            quat.y = OSFloat(cosX * sinY * cosZ - cosX * cosY * sinZ)
            quat.z = OSFloat(cosX * cosY * sinZ - sinX * sinY * cosZ)
            quat.w = OSFloat(cosX * cosY * cosZ + sinX * sinY * sinZ)
            normalize(&quat)
            
            let direction = NSValue(scnVector4: quat)
            directionMotion.values!.insert(direction, at: frameIndex)
        }
        
        let duration = Double(self.frameLength) / self.fps
        print("light frameLength: \(self.frameLength)")
        
        for motion in [colorMotion, directionMotion] {
            let motionLength = Double(motion.keyTimes!.last!)
            motion.duration = motionLength / self.fps
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards
            
            for num in 0..<motion.keyTimes!.count {
                let keyTime = Float(motion.keyTimes![num]) / Float(motionLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
            
            self.workingAnimationGroup.animations!.append(motion)
        }
        
        self.workingAnimationGroup.duration = duration
        self.workingAnimationGroup.usesSceneTimeBase = false
        self.workingAnimationGroup.isRemovedOnCompletion = false
        self.workingAnimationGroup.fillMode = kCAFillModeForwards
    }
    
    /**
     */
    private func readShadow() {
        let shadowFrameCount = Int(getUnsignedInt())
        _ = [Any]()
        let bytesPerFrame = 9
        
        if shadowFrameCount == 0 {
            return
        }
        
        let dataLength = bytesPerFrame * shadowFrameCount
        if self.motionType != .Model {
            print("error: not model motion has shadow motion data")
            // skip data
            skip(dataLength)
            return
        }
        
        if getAvailableDataLength() < dataLength {
            print("this file doesn't have shadow data")
            skip(dataLength)
            return
        }
        
        let shadowFrameLength = 0
        let shadowMotion = CAKeyframeAnimation(keyPath: "????")

        shadowMotion.values = [AnyObject]()
        
        shadowMotion.keyTimes = [NSNumber]()
        
        for _ in 0..<shadowFrameCount {
            var frameIndex = shadowMotion.keyTimes!.count - 1
            let frameNo = Int(getUnsignedInt())
            
            // the frame number might not be sorted
            while frameIndex >= 0 {
                let k = Int(shadowMotion.keyTimes![frameIndex])
                if(k < frameNo) {
                    break
                }
                
                frameIndex -= 1
            }
            frameIndex += 1

            
            shadowMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)

            if(frameNo > self.frameLength) {
                self.frameLength = frameNo
            }

            _ = getUnsignedByte() // mode
            _ = getFloat() // distance
        }
        
        _ = Double(shadowFrameLength) / self.fps // duration
        print("shadow frameLength: \(shadowFrameLength)")
        
        for motion in [shadowMotion] {
            let motionLength = Double(motion.keyTimes!.last!)
            motion.duration = motionLength / self.fps
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards
            
            for num in 0..<motion.keyTimes!.count {
                let keyTime = Float(motion.keyTimes![num]) / Float(motionLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
            
            self.workingAnimationGroup.animations!.append(motion)
        }
        
        //self.workingAnimationGroup.duration = duration
        //self.workingAnimationGroup.usesSceneTimeBase = false
        //self.workingAnimationGroup.isRemovedOnCompletion = false
        //self.workingAnimationGroup.fillMode = kCAFillModeForwards
    }
    
    /**
     */
    private func readVisibilityAndIK() {
        let ikFrameCount = Int(getUnsignedInt())
        let ikArray = [Any]()
        let bytesPerFrame = 9
        
        if ikFrameCount == 0 {
            return
        }
        
        let dataLength = bytesPerFrame * ikFrameCount
        if self.motionType != .Model {
            print("error: not model motion has IK motion data")
            // skip data
            skip(dataLength)
            return
        }
        
        if getAvailableDataLength() < dataLength {
            print("this file doesn't have IK data")
            skip(dataLength)
            return
        }
        
        var ikFrameLength = 0
        let ikMotion = CAKeyframeAnimation(keyPath: "????")
        let hiddenMotion = CAKeyframeAnimation(keyPath: "hidden")
        
        ikMotion.values = [AnyObject]()
        hiddenMotion.values = [AnyObject]()
        
        ikMotion.keyTimes = [NSNumber]()
        hiddenMotion.keyTimes = [NSNumber]()
        
        for index in 0..<ikFrameCount {
            var frameIndex = ikMotion.keyTimes!.count - 1
            let frameNo = Int(getUnsignedInt())
            
            // the frame number might not be sorted
            while frameIndex >= 0 {
                let k = Int(ikMotion.keyTimes![frameIndex])
                if(k < frameNo) {
                    break
                }
                
                frameIndex -= 1
            }
            frameIndex += 1
            
            ikMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            hiddenMotion.keyTimes!.insert(NSNumber(integerLiteral: frameNo), at: frameIndex)
            
            if(frameNo > self.frameLength) {
                self.frameLength = frameNo
            }
            
            let visible = getUnsignedByte()
            let hidden = (visible == 0)
            let ikNum = getUnsignedInt()
            
            for no in 0..<ikNum {
                let boneName = getString(length: 20)
                let ikOn = getUnsignedByte()
            }
        }
        
        let duration = Double(ikFrameLength) / self.fps
        print("ik frameLength: \(ikFrameLength)")
        
        for motion in [ikMotion, hiddenMotion] {
            let motionLength = Double(motion.keyTimes!.last!)
            motion.duration = motionLength / self.fps
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards
            
            for num in 0..<motion.keyTimes!.count {
                let keyTime = Float(motion.keyTimes![num]) / Float(motionLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
            
            self.workingAnimationGroup.animations!.append(motion)
        }
        
        // update frame length
        self.workingAnimationGroup.duration = duration
    }
}

#endif
