//
//  MMDPMMReader.swift
//  MMDSceneKit
//
//  Created by magicien on 11/17/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit

#if os(watchOS)

    class MMDPMMReader: MMDReader {
        static func getScene(_ data: Data, directoryPath: String! = "", models: [MMDNode?]? = nil, motions: [CAAnimation?]? = nil) -> SCNScene? {
            return SCNScene()
        }
    }
    
#else
    
fileprivate class MMDVMDInfo {
    var frameNo: Int = 0
    var prev: Int = -1
    var next: Int = 0
    var posX: NSNumber!
    var posY: NSNumber!
    var posZ: NSNumber!
    var rotate: NSValue!
    var timingX: CAMediaTimingFunction!
    var timingY: CAMediaTimingFunction!
    var timingZ: CAMediaTimingFunction!
    var timingRot: CAMediaTimingFunction!
    
    init(reader: MMDPMMReader) {
        self.frameNo = Int(reader.getUnsignedInt())
        self.prev = Int(reader.getUnsignedInt())
        self.next = Int(reader.getUnsignedInt())
        
        var interpolation = [Float]()
        for _ in 0..<16 {
            interpolation.append(Float(reader.getUnsignedByte()) / 127.0)
        }

        self.posX = NSNumber(value: reader.getFloat())
        self.posY = NSNumber(value: reader.getFloat())
        self.posZ = NSNumber(value: -reader.getFloat())
        var quat = SCNQuaternion(-reader.getFloat(), -reader.getFloat(), reader.getFloat(), reader.getFloat())
        reader.normalize(&quat)
        self.rotate = NSValue(scnVector4: quat)
        
        self.timingX = CAMediaTimingFunction(controlPoints:
            interpolation[0], interpolation[1], interpolation[2], interpolation[3])
        self.timingY = CAMediaTimingFunction(controlPoints:
            interpolation[4], interpolation[5], interpolation[6], interpolation[7])
        self.timingZ = CAMediaTimingFunction(controlPoints:
            interpolation[8], interpolation[9], interpolation[10], interpolation[11])
        self.timingRot = CAMediaTimingFunction(controlPoints:
            interpolation[12], interpolation[13], interpolation[14], interpolation[15])
        
        if reader.version > 1 {
            reader.skip(1) // unknown
        }
        
        let isSelected = reader.getUnsignedByte()
        
        //print("boneFrame: frameNo: \(self.frameNo)")
    }
}


fileprivate class MMDVMDFaceInfo {
    var frameNo: Int = 0
    var prev: Int = -1
    var next: Int = 0
    var weight: NSNumber!
    
    init(reader: MMDPMMReader) {
        self.frameNo = Int(reader.getUnsignedInt())
        self.prev = Int(reader.getUnsignedInt())
        self.next = Int(reader.getUnsignedInt())
        
        self.weight = NSNumber(value: reader.getFloat())
        
        let selected = reader.getUnsignedByte()
        
        //print("faceFrame: frameNo: \(self.frameNo)")
    }
}


fileprivate class MMDVMDCameraInfo {
    var frameNo: Int = 0
    var prev: Int = -1
    var next: Int = 0
    var distance: NSNumber!
    var posX: NSNumber!
    var posY: NSNumber!
    var posZ: NSNumber!
    var rotX: NSNumber!
    var rotY: NSNumber!
    var rotZ: NSNumber!
    var angle: NSNumber!
    var useOrtho: NSNumber!

    var timingDistance: CAMediaTimingFunction!
    var timingX: CAMediaTimingFunction!
    var timingY: CAMediaTimingFunction!
    var timingZ: CAMediaTimingFunction!
    var timingRot: CAMediaTimingFunction!
    var timingAngle: CAMediaTimingFunction!
    
    init(reader: MMDPMMReader) {
        self.frameNo = Int(reader.getUnsignedInt())
        self.prev = Int(reader.getUnsignedInt())
        self.next = Int(reader.getUnsignedInt())
        
        self.distance = NSNumber(value: -reader.getFloat())
        self.posX = NSNumber(value: reader.getFloat())
        self.posY = NSNumber(value: reader.getFloat())
        self.posZ = NSNumber(value: -reader.getFloat())
        self.rotX = NSNumber(value: reader.getFloat())
        self.rotY = NSNumber(value: reader.getFloat())
        self.rotZ = NSNumber(value: -reader.getFloat())
        
        var followModelIndex = -1
        var followBoneIndex: UInt32 = 0
        
        if reader.version > 1 {
            followModelIndex = Int(reader.getInt())
            followBoneIndex = reader.getUnsignedInt()
        }
        
        if followModelIndex >= 0 {
            //let model = reader.models[followModelIndex]
        }
        
        var interpolation = [Float]()
        for _ in 0..<24 {
            interpolation.append(Float(reader.getUnsignedByte()) / 127.0)
        }
        
        self.timingX = CAMediaTimingFunction(controlPoints:
            interpolation[0], interpolation[1], interpolation[2], interpolation[3])
        self.timingY = CAMediaTimingFunction(controlPoints:
            interpolation[4], interpolation[5], interpolation[6], interpolation[7])
        self.timingZ = CAMediaTimingFunction(controlPoints:
            interpolation[8], interpolation[9], interpolation[10], interpolation[11])
        self.timingRot = CAMediaTimingFunction(controlPoints:
            interpolation[12], interpolation[13], interpolation[14], interpolation[15])
        self.timingDistance = CAMediaTimingFunction(controlPoints:
            interpolation[16], interpolation[17], interpolation[18], interpolation[19])
        self.timingAngle = CAMediaTimingFunction(controlPoints:
            interpolation[20], interpolation[21], interpolation[22], interpolation[23])
        //print("=====")
        //print("timingDistance: \(self.timingDistance)")
        //print("timingX: \(self.timingX)")
        //print("timingY: \(self.timingY)")
        //print("timingZ: \(self.timingZ)")
        //print("timingRot: \(self.timingRot)")
        //print("timingAngle: \(self.timingAngle)")
        
        
        let perspective = reader.getUnsignedByte()
        self.useOrtho = NSNumber(booleanLiteral: (perspective != 0))
        self.angle = NSNumber(value: reader.getInt())
        //print("camera angle \(self.angle)")
        
        let isSelected = reader.getUnsignedByte()
    }
}


fileprivate class MMDVMDLightInfo {
    var frameNo: Int = 0
    var prev: Int = -1
    var next: Int = 0
    
    //var color: CGColor!
    #if os(iOS) || os(tvOS) || os(watchOS)
        var color: UIColor!
    #elseif os(OSX)
        var color: NSColor!
    #endif
    
    var direction: NSValue!
    
    init(reader: MMDPMMReader) {
        self.frameNo = Int(reader.getUnsignedInt())
        self.prev = Int(reader.getUnsignedInt())
        self.next = Int(reader.getUnsignedInt())

        #if os(iOS) || os(tvOS) || os(watchOS)
            let color = UIColor(red: reader.getCGFloat(), green: reader.getCGFloat(), blue: reader.getCGFloat(), alpha: 1.0)
        #elseif os(macOS)
            let color = NSColor(red: reader.getCGFloat(), green: reader.getCGFloat(), blue: reader.getCGFloat(), alpha: 1.0)
        #endif
        self.color = color
        
        //print("Light @ \(self.frameNo): \(color.redComponent), \(color.greenComponent), \(color.blueComponent)")
        let rotX = -reader.getFloat()
        let rotY = -reader.getFloat()
        let rotZ = reader.getFloat()

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
        reader.normalize(&quat)
        
        self.direction = NSValue(scnVector4: quat)
        
        let isSelected = reader.getUnsignedByte() // Is it correct?
    }
}


fileprivate class MMDVMDAccessoryInfo {
    var frameNo: Int = 0
    var prev: Int = -1
    var next: Int = 0
    
    var model: NSNumber!
    var bone: NSNumber!
    
    /*
    var posX: NSNumber!
    var posY: NSNumber!
    var posZ: NSNumber!
 */
    var position: NSValue!
    var rotation: NSValue!
    var scale: NSValue!
    
    var isHidden: NSNumber!
    var opacity: NSNumber!
    var additive: SCNBlendMode!
    var castsShadow: NSNumber!
    var parent: MMDNode?
    
    init(reader: MMDPMMReader) {
        self.frameNo = Int(reader.getUnsignedInt())
        self.prev = Int(reader.getUnsignedInt())
        self.next = Int(reader.getUnsignedInt())
        
        //print("frameNo: \(self.frameNo), prev: \(self.prev), next: \(self.next)")

        let visibility = reader.getUnsignedByte()
        let isVisible = visibility & 0x01
        let opacity = Float(100 - (visibility >> 1)) * 0.01
        
        self.isHidden = NSNumber(booleanLiteral: (isVisible == 0))
        self.opacity = NSNumber(value: opacity)
        
        let modelIndexUInt = reader.getUnsignedInt()
        let boneIndex = Int(reader.getUnsignedInt())

        var modelIndex = Int(modelIndexUInt)
        if modelIndexUInt == 0xFFFFFFFF {
            modelIndex = -1
        }

        var parentNode: MMDNode? = nil
        if modelIndex >= 0 && modelIndex < reader.models.count {
            let parentModel = reader.models[modelIndex]
            
            //print(String(format: "<Pointer> MMDVMDAccessoryInfo parentModel: %p", parentModel))
            if boneIndex < parentModel.boneArray.count {
                guard let boneName = parentModel.boneArray[boneIndex].name else {
                    fatalError("bone.name == nil")
                }
                parentNode = parentModel.childNode(withName: boneName, recursively: true) as? MMDNode
                guard parentNode != nil else {
                    fatalError("parentNode == nil")
                }
                
                print("accessory parentNode: \(String(describing: parentNode!.name))")
                //print(String(format: "<Pointer><Center> MMDVMDAccessoryInfo parentNode: %p", parentNode!))
                
                //var node:SCNNode? = parentNode
                //while node != nil {
                //    print(String(format: "<Pointer><Recursive>%@: %p", node!.name ?? "", node!))
                //    node = node!.parent
                //}
            }
        }
        self.parent = parentNode
        
        let pos = SCNVector3Make(OSFloat(reader.getFloat()), OSFloat(reader.getFloat()), OSFloat(reader.getFloat()))
        self.position = NSValue(scnVector3: pos)
        
        let rotX = -reader.getFloat()
        let rotY = -reader.getFloat()
        let rotZ = reader.getFloat()
        
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
        reader.normalize(&quat)
        
        self.rotation = NSValue(scnVector4: quat)
        let scale = OSFloat(reader.getFloat() * 10.0)
        self.scale = NSValue(scnVector3: SCNVector3Make(scale, scale, scale))

        // shadow/additive ?
        let flag = reader.getUnsignedByte()

        let isSelected = reader.getUnsignedByte()
        
        if (flag & 0x01) == 0 {
            self.additive = .add
        } else {
            self.additive = .alpha
        }
        //self.additive = NSNumber(booleanLiteral: ((flag & 0x01) != 0))

        print("modelIndex: \(modelIndex)")
        
        print("    pos: \(pos)")
        print("    rot: \(rotX), \(rotY), \(rotZ)")
        print("    scale: \(scale), opacity: \(opacity), isHidden: \(isHidden)")
        print("    flag1: \(flag), isSelected: \(isSelected)")
    }
}


class MMDPMMReader: MMDReader {
    private var workingScene: SCNScene! = nil
    
    // MARK: PMM header data
    private var pmmMagic: String! = ""
    var version: Int = 0
    
    var fps: Double = 30.0
    
    private var boneCount: Int = 0
    private var boneNameArray: [String]! = nil
    
    private var faceCount: Int = 0
    private var faceNameArray: [String]! = nil
    
    private var ikCount: Int = 0
    private var ikIndexArray: [Int]! = nil
    
    private var parentCount: Int = 0
    
    private var accessoryCount: Int = 0
    private var accessoryNameArray: [String]! = nil
    private var accessories = [MMDNode]()
    
    private var modelCount: Int = 0
    var models = [MMDNode]()
    private var workingModel: MMDNode! = nil
    private var motions = [CAAnimationGroup]()
    
    private var substituteModels: [MMDNode?]! = nil
    private var substituteMotions: [CAAnimation?]! = nil
    
    // for animation
    private var frameLength: Int = 0
    private var workingAnimationGroup: CAAnimationGroup! = nil
    private var animationHash: [String: CAKeyframeAnimation]! = nil
    private var faceAnimationHash: [String: CAKeyframeAnimation]! = nil
    
    private var initialBoneFrame: [MMDVMDInfo]! = nil
    private var boneFrameHash: [Int: MMDVMDInfo]! = nil
    private var initialFaceFrame: [MMDVMDFaceInfo]! = nil
    private var faceFrameHash: [Int: MMDVMDFaceInfo]! = nil
    
    // for accessory animation
    private var initialAccessoryFrame: MMDVMDAccessoryInfo! = nil
    private var accessoryFrameHash: [Int: MMDVMDAccessoryInfo]! = nil
    private var accessoryMotions = [CAAnimationGroup]()

    // for camera animation
    private var workingCameraAnimationGroup: CAAnimationGroup! = nil
    private var initialCameraFrame: MMDVMDCameraInfo! = nil
    private var cameraFrameHash: [Int: MMDVMDCameraInfo]! = nil
    
    // for light animation
    private var workingLightAnimationGroup: CAAnimationGroup! = nil
    private var initialLightFrame: MMDVMDLightInfo! = nil
    private var lightFrameHash: [Int: MMDVMDLightInfo]! = nil
    

    let userFilePathPattern = Regexp("\\\\UserFile\\\\(.*)$")

    /**
     
     */
    static func getScene(_ data: Data, directoryPath: String! = "", models: [MMDNode?]? = nil, motions: [CAAnimation?]? = nil) -> SCNScene? {
        
        //print(String(format: "<Pointer> MMDPMMReader.getScene models[0]: %p", models![0]!))
        let reader = MMDPMMReader(data: data, directoryPath: directoryPath)
        let scene = reader.loadPMMFile(models: models, motions: motions)
        
        return scene
    }
    
    // MARK: - Loading PMM File
    /**
     * load .pmm file
     * - return:
     */
    private func loadPMMFile(models: [MMDNode?]? = nil, motions: [CAAnimation?]? = nil) -> SCNScene? {
        // initialize working variables
        self.workingScene = SCNScene()
        
        self.pmmMagic = ""
        self.version = 0
        
        self.substituteModels = models
        if self.substituteModels == nil {
            self.substituteModels = [MMDNode?]()
        }
        
        // read contents of file
        self.readPMMHeader()
        if self.version == 1 {
            return loadPMMFile_v1()
        } else if self.version == 2 {
            return loadPMMFile_v2()
        } else {
            // unknown file format
            print("unknown file format: \(self.pmmMagic)")
            return nil
        }
    }

    /**
     * load .pmm Version1 file
     */
    private func loadPMMFile_v1() -> SCNScene? {
        readModels()
        readCameras()
        readLights()
        readAccessories()
        
        readSettings()
        
        setupScene()
        
        return self.workingScene
    }

    /**
     * load .pmm Version2 file
     */
    private func loadPMMFile_v2() -> SCNScene? {
        readModels()
        readCameras()
        readLights()
        readAccessories()

        readSettings()
        
        setupScene()

        return self.workingScene
    }
    
    /**
     read PMD header data
     */
    private func readPMMHeader() {
        self.pmmMagic = String(getString(length: 30)!)
        print("pmmMagic: \(pmmMagic)")
        
        if self.pmmMagic == "Polygon Movie maker 0001" {
            self.version = 1
        } else if self.pmmMagic == "Polygon Movie maker 0002" {
            self.version = 2
        }
        
        let movieWidth = getInt()
        let movieHeight = getInt()
        let frameWindowWidth = getInt()
        let viewAngle = getFloat()
        let isCameraMode = getUnsignedByte()
        
        print("movie size: (\(movieWidth), \(movieHeight))")
        skip(6) // skip unknown bytes
        
        if self.version == 2 {
            skip(1) // ?
        }
    }

    private func readModels() {
        self.modelCount = Int(getUnsignedByte())
        print("modelCount: \(self.modelCount)")
        
        if self.version == 1 {
            for _ in 0..<self.modelCount {
                var modelName = ""
                if let text = getString(length: 20) as String? {
                    modelName = text
                }
                print("modelName: \(modelName)")
            }
        }
        
        if self.modelCount > self.substituteModels.count {
            for _ in 0..<(self.modelCount - self.substituteModels.count) {
                self.substituteModels.append(nil)
            }
        }
        
        for modelNo in 0..<self.modelCount {
            var model = MMDNode()
            if let m = self.substituteModels[modelNo] {
                model = m
                
                // just skip data
                skip(1)
                if version == 1 {
                    skip(20)
                } else {
                    let a = getPascalString() as String
                    let b = getPascalString() as String
                    print("\(a), \(b)")
                }
                skip(257)
            } else {
                let no = getUnsignedByte()
                
                if version == 1 {
                    model.name = getString(length: 20)! as String
                } else {
                    model.name = getPascalString() as String
                    let englishName = getPascalString() as String
                }
                
                let filePath = getString(length: 256)
                skip(1) // unknown flag
                
                print("\(String(describing: model.name)): filePath: \(String(describing: filePath))")
                
                let filePathMatches = userFilePathPattern.matches(filePath! as String)
                if let paths = filePathMatches {
                    let replaced = paths[1].replacingOccurrences(of: "\\", with: "/")
                    let newFilePath = self.directoryPath + "/" + replaced
                    print("newFilePath: \(newFilePath)")
                    
                    if let modelScene = MMDSceneSource(path: newFilePath) {
                        if let newModel = modelScene.getModel() {
                            model = newModel
                        } else {
                            print("can't get model data: \(newFilePath)")
                        }
                    } else {
                        print("can't read file: \(newFilePath)")
                    }
                }
            }
            self.workingModel = model

            if self.version == 1 {
                self.boneCount = model.boneArray.count - 1
                self.boneNameArray = [String]()
                /*
                for index in 1..<model.boneArray.count {
                    self.boneNameArray.append(model.boneArray[index].name!)
                }
                 */
                for bone in model.boneArray {
                    self.boneNameArray.append(bone.name!)
                }
                
                self.faceCount = model.geometryMorpher.targets.count
                self.faceNameArray = [String]()
                for face in model.geometryMorpher.targets {
                    self.faceNameArray.append(face.name!)
                }
                
                self.ikCount = model.ikArray!.count
                self.ikIndexArray = [Int]()
                // TODO: set ikIndexArray
                
                self.parentCount = 0
            } else {
                readBone()
                readFace()
                readIK()
                readParent()
                
                skip(1) // unknown flag
            }
            
            let visible = getUnsignedByte()
            let selectedBone = getUnsignedInt()
            let morph_eyebrows = getUnsignedInt()
            let morph_eyes = getUnsignedInt()
            let morph_lips = getUnsignedInt()
            let morph_etc = getUnsignedInt()
            
            let frameCount = getUnsignedByte()
            for _ in 0..<frameCount {
                _ = getUnsignedByte() // the frame is shown if it's true...
            }
            
            skip(4) // unknown

            
            // read motions
            let lastFrame = getUnsignedInt()
            print("lastFrame: \(lastFrame)")
            
            self.workingAnimationGroup = CAAnimationGroup()
            self.workingAnimationGroup.animations = [CAAnimation]()
            
            self.animationHash = [String: CAKeyframeAnimation]()
            self.faceAnimationHash = [String: CAKeyframeAnimation]()
            
            self.frameLength = 0

            
            readBoneFrames()
            readFaceFrames()
            readIKFrames()
            
            createAnimations()
            
            readBoneStatus()
            readFaceStatus()
            readIKStatus()
            readParentStatus()
            
            if self.version > 1 {
                skip(7) // ?
            }
            
            self.models.append(model)
        }
        
        //print(String(format: "<Pointer> MMDPMMReader.readModels self.models[0]: %p", self.models[0]))

    }
    
    private func readBone() {
        self.boneCount = Int(getUnsignedInt())
        print("boneCount: \(boneCount)")
        
        self.boneNameArray = [String]()
        for _ in 0..<self.boneCount {
            self.boneNameArray.append(getPascalString() as String)
        }
        
        for boneName in self.boneNameArray {
            //print("    bone: \(boneName)")
        }
    }
    
    private func readFace() {
        self.faceCount = Int(getUnsignedInt())
        self.faceNameArray = [String]()
        for _ in 0..<self.faceCount {
            self.faceNameArray.append(getPascalString() as String)
        }
        
        for faceName in self.faceNameArray {
            //print("    face: \(faceName)")
        }
    }
    
    private func readIK() {
        self.ikCount = Int(getUnsignedInt())
        print("ikCount: \(ikCount)")
        self.ikIndexArray = [Int]()
        for _ in 0..<self.ikCount {
            self.ikIndexArray.append(Int(getUnsignedInt()))
        }
    }
    
    private func readParent() {
        self.parentCount = Int(getUnsignedInt())
        print("parentCount: \(self.parentCount)")
        for _ in 0..<parentCount {
            _ = getUnsignedInt()
        }
    }
    
    // MARK: - Bone Frame
    
    private func readBoneFrames() {
        self.initialBoneFrame = [MMDVMDInfo]()
        self.boneFrameHash = [Int:MMDVMDInfo]()
        
        for _ in 0..<self.boneCount {
            readOneBoneFrame(hasIndex: false)
        }
        
        let boneFrameCount = getUnsignedInt()
        print("boneFrameCount: \(boneFrameCount)")
        for _ in 0..<boneFrameCount {
            readOneBoneFrame()
        }
        
        // create animation data
        for index in 0..<self.boneCount {
            let boneName = self.boneNameArray[index]
            
            print("============== bone animation: \(boneName) =====================")
            
            let posXMotion = CAKeyframeAnimation(keyPath: "/\(boneName).transform.translation.x")
            let posYMotion = CAKeyframeAnimation(keyPath: "/\(boneName).transform.translation.y")
            let posZMotion = CAKeyframeAnimation(keyPath: "/\(boneName).transform.translation.z")
            let rotMotion = CAKeyframeAnimation(keyPath: "/\(boneName).transform.quaternion")
            
            posXMotion.values = [AnyObject]()
            posYMotion.values = [AnyObject]()
            posZMotion.values = [AnyObject]()
            rotMotion.values = [AnyObject]()
            
            posXMotion.keyTimes = [NSNumber]()
            posYMotion.keyTimes = [NSNumber]()
            posZMotion.keyTimes = [NSNumber]()
            rotMotion.keyTimes = [NSNumber]()
            
            posXMotion.timingFunctions = [CAMediaTimingFunction]()
            posYMotion.timingFunctions = [CAMediaTimingFunction]()
            posZMotion.timingFunctions = [CAMediaTimingFunction]()
            rotMotion.timingFunctions = [CAMediaTimingFunction]()
            
            self.animationHash["posX:\(boneName)"] = posXMotion
            self.animationHash["posY:\(boneName)"] = posYMotion
            self.animationHash["posZ:\(boneName)"] = posZMotion
            self.animationHash["rot:\(boneName)"] = rotMotion
            
            self.addMotionRecursive(info: self.initialBoneFrame[index],
                                    posXMotion: posXMotion,
                                    posYMotion: posYMotion,
                                    posZMotion: posZMotion,
                                    rotMotion: rotMotion)
        }
    }
    
    private func addMotionRecursive(
        info: MMDVMDInfo,
        posXMotion: CAKeyframeAnimation,
        posYMotion: CAKeyframeAnimation,
        posZMotion: CAKeyframeAnimation,
        rotMotion: CAKeyframeAnimation) {
        
        var frameIndex = posXMotion.keyTimes!.count - 1

        // the frame number might not be sorted
        while frameIndex >= 0 {
            let k = posXMotion.keyTimes![frameIndex].intValue
            if(k < info.frameNo) {
                break
            }
            
            frameIndex -= 1
        }
        frameIndex += 1
        
        if(info.frameNo > self.frameLength) {
            self.frameLength = info.frameNo
        }
        let nsFrameNo = NSNumber(integerLiteral: info.frameNo)
        
        posXMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        posYMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        posZMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        rotMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        
        posXMotion.timingFunctions!.insert(info.timingX, at: frameIndex)
        posYMotion.timingFunctions!.insert(info.timingY, at: frameIndex)
        posZMotion.timingFunctions!.insert(info.timingZ, at: frameIndex)
        rotMotion.timingFunctions!.insert(info.timingRot, at: frameIndex)
        
        posXMotion.values!.insert(info.posX, at: frameIndex)
        posYMotion.values!.insert(info.posY, at: frameIndex)
        posZMotion.values!.insert(info.posZ, at: frameIndex)
        rotMotion.values!.insert(info.rotate, at: frameIndex)
        
        print("frameNo: \(info.frameNo)")
        print("pos: \(info.posX), \(info.posY), \(info.posZ)")
        print("rot: \(info.rotate)")

        if info.next > 0 {
            if let nextMotion = self.boneFrameHash[info.next] {
                self.addMotionRecursive(info: nextMotion,
                                        posXMotion: posXMotion,
                                        posYMotion: posYMotion,
                                        posZMotion: posZMotion,
                                        rotMotion: rotMotion)
            } else {
                print("error: the frame index(\(info.next)) doesn't exist.")
            }
        }
    }
    
    private func readOneBoneFrame(hasIndex: Bool = true) {
        var index: Int = 0
        if hasIndex {
            index = Int(getUnsignedInt())
        }
        /*
        let frameNo = getUnsignedInt()
        let prev = getUnsignedInt()
        let next = getUnsignedInt()
        
        var interpolation = [Float]()
        for _ in 0..<16 {
            interpolation.append(Float(getUnsignedByte()) / 127.0)
        }
        let transX = getFloat()
        let transY = getFloat()
        let transZ = getFloat()
        let quatX = getFloat()
        let quatY = getFloat()
        let quatZ = getFloat()
        let quatW = getFloat()
        
        if self.version > 1 {
            skip(1) // unknown
        }
        
        let isSelected = getUnsignedByte()
 
        print("boneFrame: frameNo: \(frameNo)")
         */
        let vmdInfo = MMDVMDInfo(reader: self)
        if hasIndex {
            self.boneFrameHash[index] = vmdInfo
        } else {
            self.initialBoneFrame.append(vmdInfo)
        }
    }
    
    
    // MARK: - Face Frame
    
    private func readFaceFrames() {
        self.initialFaceFrame = [MMDVMDFaceInfo]()
        self.faceFrameHash = [Int:MMDVMDFaceInfo]()

        print("faceCount: \(self.faceCount)")
        for _ in 0..<self.faceCount {
            readOneFaceFrame(hasIndex: false)
        }
        let faceFrameCount = getUnsignedInt()
        print("faceFrameCount: \(faceFrameCount)")
        for _ in 0..<faceFrameCount {
            readOneFaceFrame()
        }
        
        // create animation data
        for index in 0..<self.faceCount {
            let faceName = self.faceNameArray[index]
            
            let faceMotion = CAKeyframeAnimation(keyPath: "morpher.weights.\(faceName)")
            faceMotion.values = [AnyObject]()
            faceMotion.keyTimes = [NSNumber]()
            faceMotion.timingFunctions = [CAMediaTimingFunction]()
            
            self.faceAnimationHash[faceName] = faceMotion
            
            self.addFaceMotionRecursive(info: self.initialFaceFrame[index], faceMotion: faceMotion)
        }
    }
    
    private func readOneFaceFrame(hasIndex: Bool = true) {
        var index: Int = 0
        if hasIndex {
            index = Int(getUnsignedInt())
        }
        /*
        let frameNo = getUnsignedInt()
        let prev = getUnsignedInt()
        let next = getUnsignedInt()
        
        let weight = getFloat()
        let selected = getUnsignedByte()
        
        //print("readOneFaceFrame: selected: \(selected)")
        print("faceFrame: frameNo: \(frameNo)")
 */
        let faceInfo = MMDVMDFaceInfo(reader: self)
        if hasIndex {
            self.faceFrameHash[index] = faceInfo
        } else {
            self.initialFaceFrame.append(faceInfo)
        }
    }
    
    private func addFaceMotionRecursive(info: MMDVMDFaceInfo, faceMotion: CAKeyframeAnimation) {
        var frameIndex = faceMotion.keyTimes!.count - 1
        
        // the frame number might not be sorted
        while frameIndex >= 0 {
            let k = faceMotion.keyTimes![frameIndex].intValue
            if(k < info.frameNo) {
                break
            }
            
            frameIndex -= 1
        }
        frameIndex += 1
        
        if(info.frameNo > self.frameLength) {
            self.frameLength = info.frameNo
        }
        let nsFrameNo = NSNumber(integerLiteral: info.frameNo)
        let timingFunc = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)

        faceMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        faceMotion.timingFunctions!.insert(timingFunc, at: frameIndex)
        faceMotion.values!.insert(info.weight, at: frameIndex)
        
        if info.next > 0 {
            if let nextMotion = self.faceFrameHash[info.next] {
                self.addFaceMotionRecursive(info: nextMotion, faceMotion: faceMotion)
            } else {
                print("error: the face frame index(\(info.next)) doesn't exist.")
            }
        }
    }

    
    // MARK: - IK Frame
    
    private func readIKFrames() {
        print("ikCount: \(self.ikCount)")
        print("parentCount: \(self.parentCount)")

        readOneIKFrame(hasIndex: false)
        
        let boneIKCount = getUnsignedInt()
        print("boneIKCount: \(boneIKCount)")
        for _ in 0..<boneIKCount {
            readOneIKFrame()
        }
    }
    
    private func readOneIKFrame(hasIndex: Bool = true) {
        var index: UInt32 = 0
        if hasIndex {
            index = getUnsignedInt()
        }
        let frameNo = getUnsignedInt()
        let prev = getUnsignedInt()
        let next = getUnsignedInt()
        
        let isVisible = getUnsignedByte()
        for _ in 0..<self.ikCount {
            let isEnable = getUnsignedByte()
        }
        
        // if the version is 1.0, parentCount is 0.
        for _ in 0..<self.parentCount {
            let modelIndex = getUnsignedInt()
            let boneIndex = getUnsignedInt()
        }
        
        let isSelected = getUnsignedByte()
        
        /*
        print("IK Frame: frameNo: \(frameNo)")
        print("    prev: \(prev)")
        print("    next: \(next)")
        print("    isVisible: \(isVisible)")
        print("    isSelected: \(isSelected)")
         */
    }
    
    // MARK: - Create Animation
    
    /**
     */
    private func createAnimations() {
        let duration = Double(self.frameLength) / self.fps
        print("bone frameLength: \(self.frameLength)")
        
        for (name, motion) in self.animationHash {
            let motionLength: Double = motion.keyTimes!.last!.doubleValue
            
            for num in 0..<motion.keyTimes!.count {
                let keyTime = motion.keyTimes![num].floatValue / Float(motionLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
            
            motion.duration = motionLength / self.fps
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards
            
            if motion.keyTimes!.count == 1 {
                motion.repeatCount = Float.infinity
            }
            
            self.workingAnimationGroup.animations!.append(motion)
        }
        
        for (_, motion) in self.faceAnimationHash {
            let motionLength: Float = motion.keyTimes!.last!.floatValue
            
            //print("faceAnimation: \(motion.keyPath!)")
            for num in 0..<motion.keyTimes!.count {
                let keyTime: Float = motion.keyTimes![num].floatValue / motionLength
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
            
            motion.duration = CFTimeInterval(motionLength / Float(self.fps))
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards
            
            self.workingAnimationGroup.animations!.append(motion)
        }
        
        self.workingAnimationGroup.duration = duration
        self.workingAnimationGroup.usesSceneTimeBase = false
        self.workingAnimationGroup.isRemovedOnCompletion = false
        self.workingAnimationGroup.fillMode = kCAFillModeForwards

        
        self.motions.append(self.workingAnimationGroup)
    }

    
    private func readBoneStatus() {
        // float3 translation
        // float4 rotation
        // bool isMoving?
        // bool enabledPhysics?
        // bool isSelected
        
        // just ignore data
        if version == 1 {
            skip(34 * self.boneCount)
        } else {
            skip(31 * self.boneCount) // 34 byte?
        }
    }
    
    private func readFaceStatus() {
        // float skinValue
        
        // just ignore data
        skip(4 * self.faceCount)
    }
    
    private func readIKStatus() {
        // bool ikIsEnable
        skip(self.ikCount)
    }
    
    private func readParentStatus() {
        // int4 parentStatus
        skip(16 * self.parentCount)
    }
    
    // MARK: - Camera Frame
    private func readCameras() {
        self.workingCameraAnimationGroup = CAAnimationGroup()
        self.workingCameraAnimationGroup.animations = [CAAnimation]()
        self.cameraFrameHash = [Int:MMDVMDCameraInfo]()
        
        self.frameLength = 0

        readOneCameraFrame(hasIndex: false)
        
        let cameraFrameCount = getUnsignedInt()
        print("cameraFrameCount: \(cameraFrameCount)")
        for _ in 0..<cameraFrameCount {
            readOneCameraFrame()
        }
        
        createCameraAnimation()
        
        readCameraStatus()
    }
    
    private func readOneCameraFrame(hasIndex: Bool = true) {
        var index: Int = -1
        if hasIndex {
            index = Int(getUnsignedInt())
        }
        /*
        let frameNo = getUnsignedInt()
        print("camera frameNo: \(frameNo)")
        let prev = getUnsignedInt()
        let next = getUnsignedInt()
        let distance = getFloat()
        let posX = getFloat()
        let posY = getFloat()
        let posZ = getFloat()
        let rotX = getFloat()
        let rotY = getFloat()
        let rotZ = getFloat()

        var followModelIndex = -1
        var followBoneIndex: UInt32 = 0

        if self.version > 1 {
            followModelIndex = Int(getInt())
            followBoneIndex = getUnsignedInt()
        }
        
        if followModelIndex >= 0 {
            let model = self.models[followModelIndex]
        }
        
        var interpolation = [Float]()
        for _ in 0..<24 {
            interpolation.append(Float(getUnsignedByte()) / 127.0)
        }
        
        let parse = getUnsignedByte()
        let fov = getFloat()
        let isSelected = getUnsignedByte()
 */
        let cameraInfo = MMDVMDCameraInfo(reader: self)
        if hasIndex {
            self.cameraFrameHash[index] = cameraInfo
        } else {
            self.initialCameraFrame = cameraInfo
        }
    }
    
    private func addCameraMotionRecursive(
        info: MMDVMDCameraInfo,
        distanceMotion: CAKeyframeAnimation,
        posXMotion: CAKeyframeAnimation,
        posYMotion: CAKeyframeAnimation,
        posZMotion: CAKeyframeAnimation,
        rotXMotion: CAKeyframeAnimation,
        rotYMotion: CAKeyframeAnimation,
        rotZMotion: CAKeyframeAnimation,
        angleMotion: CAKeyframeAnimation,
        persMotion: CAKeyframeAnimation) {
        
        var frameIndex = distanceMotion.keyTimes!.count - 1
        
        // the frame number might not be sorted
        while frameIndex >= 0 {
            let k = distanceMotion.keyTimes![frameIndex].intValue
            if(k < info.frameNo) {
                break
            }
            
            frameIndex -= 1
        }
        frameIndex += 1

        if(info.frameNo > self.frameLength) {
            self.frameLength = info.frameNo
        }
        let nsFrameNo = NSNumber(integerLiteral: info.frameNo)
        
        distanceMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        posXMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        posYMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        posZMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        rotXMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        rotYMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        rotZMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        angleMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        persMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        
        distanceMotion.timingFunctions!.insert(info.timingDistance, at: frameIndex)
        posXMotion.timingFunctions!.insert(info.timingX, at: frameIndex)
        posYMotion.timingFunctions!.insert(info.timingY, at: frameIndex)
        posZMotion.timingFunctions!.insert(info.timingZ, at: frameIndex)
        rotXMotion.timingFunctions!.insert(info.timingRot, at: frameIndex)
        rotYMotion.timingFunctions!.insert(info.timingRot, at: frameIndex)
        rotZMotion.timingFunctions!.insert(info.timingRot, at: frameIndex)
        angleMotion.timingFunctions!.insert(info.timingAngle, at: frameIndex)
        
        distanceMotion.values!.insert(info.distance, at: frameIndex)
        posXMotion.values!.insert(info.posX, at: frameIndex)
        posYMotion.values!.insert(info.posY, at: frameIndex)
        posZMotion.values!.insert(info.posZ, at: frameIndex)
        rotXMotion.values!.insert(info.rotX, at: frameIndex)
        rotYMotion.values!.insert(info.rotY, at: frameIndex)
        rotZMotion.values!.insert(info.rotZ, at: frameIndex)
        angleMotion.values!.insert(info.angle, at: frameIndex)
        persMotion.values!.insert(info.useOrtho, at: frameIndex)
        
        /*
        print("camera frameNo: \(info.frameNo)")
        print("       distance: \(info.distance)")
        print("       pos: \(info.posX), \(info.posY), \(info.posZ)")
        print("       rot: \(info.rotX), \(info.rotY), \(info.rotZ)")
        print("       angle: \(info.angle), ortho: \(info.useOrtho)")
        print()
 */
        
        if info.next > 0 {
            if let nextMotion = self.cameraFrameHash[info.next] {
                self.addCameraMotionRecursive(info: nextMotion,
                                              distanceMotion: distanceMotion,
                                              posXMotion: posXMotion,
                                              posYMotion: posYMotion,
                                              posZMotion: posZMotion,
                                              rotXMotion: rotXMotion,
                                              rotYMotion: rotYMotion,
                                              rotZMotion: rotZMotion,
                                              angleMotion: angleMotion,
                                              persMotion: persMotion)
            } else {
                print("error: the camera frame index(\(info.next)) doesn't exist.")
            }
        }
    }
    
    private func createCameraAnimation() {
        let distanceMotion = CAKeyframeAnimation(keyPath: "/\(MMD_CAMERA_NODE_NAME).translation.z")
        let posXMotion = CAKeyframeAnimation(keyPath: "transform.translation.x")
        let posYMotion = CAKeyframeAnimation(keyPath: "transform.translation.y")
        let posZMotion = CAKeyframeAnimation(keyPath: "transform.translation.z")
        let rotZMotion = CAKeyframeAnimation(keyPath: "/\(MMD_CAMERA_ROTZ_NODE_NAME).eulerAngles.z")
        let rotXMotion = CAKeyframeAnimation(keyPath: "/\(MMD_CAMERA_ROTX_NODE_NAME).eulerAngles.x")
        let rotYMotion = CAKeyframeAnimation(keyPath: "eulerAngles.y")
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
        
        self.frameLength = 0
        self.addCameraMotionRecursive(info: self.initialCameraFrame,
                                      distanceMotion: distanceMotion,
                                      posXMotion: posXMotion,
                                      posYMotion: posYMotion,
                                      posZMotion: posZMotion,
                                      rotXMotion: rotXMotion,
                                      rotYMotion: rotYMotion,
                                      rotZMotion: rotZMotion,
                                      angleMotion: angleMotion,
                                      persMotion: persMotion)
        
        let duration = Double(self.frameLength) / self.fps
        print("camera frameLength: \(self.frameLength)")
        
        for motion in [distanceMotion, posXMotion, posYMotion, posZMotion, rotXMotion, rotYMotion, rotZMotion, angleMotion, persMotion] {
            let motionLength = motion.keyTimes!.last!.doubleValue
            motion.duration = motionLength / self.fps
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards
            
            for num in 0..<motion.keyTimes!.count {
                let keyTime: Float = motion.keyTimes![num].floatValue / Float(motionLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
            
            self.workingCameraAnimationGroup.animations!.append(motion)
        }
        
        /*
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
        
        distanceMotion.isRemovedOnCompletion = false
        posXMotion.isRemovedOnCompletion = false
        posYMotion.isRemovedOnCompletion = false
        posZMotion.isRemovedOnCompletion = false
        rotXMotion.isRemovedOnCompletion = false
        rotYMotion.isRemovedOnCompletion = false
        rotZMotion.isRemovedOnCompletion = false
        angleMotion.isRemovedOnCompletion = false
        persMotion.isRemovedOnCompletion = false

        distanceMotion.fillMode = kCAFillModeForwards
        posXMotion.fillMode = kCAFillModeForwards
        posYMotion.fillMode = kCAFillModeForwards
        posZMotion.fillMode = kCAFillModeForwards
        rotXMotion.fillMode = kCAFillModeForwards
        rotYMotion.fillMode = kCAFillModeForwards
        rotZMotion.fillMode = kCAFillModeForwards
        angleMotion.fillMode = kCAFillModeForwards
        persMotion.fillMode = kCAFillModeForwards
        
        
        
        self.workingCameraAnimationGroup.animations!.append(distanceMotion)
        self.workingCameraAnimationGroup.animations!.append(posXMotion)
        self.workingCameraAnimationGroup.animations!.append(posYMotion)
        self.workingCameraAnimationGroup.animations!.append(posZMotion)
        self.workingCameraAnimationGroup.animations!.append(rotXMotion)
        self.workingCameraAnimationGroup.animations!.append(rotYMotion)
        self.workingCameraAnimationGroup.animations!.append(rotZMotion)
        self.workingCameraAnimationGroup.animations!.append(angleMotion)
        self.workingCameraAnimationGroup.animations!.append(persMotion)
 */
        self.workingCameraAnimationGroup.duration = duration
        self.workingCameraAnimationGroup.usesSceneTimeBase = false
        self.workingCameraAnimationGroup.isRemovedOnCompletion = false
        self.workingCameraAnimationGroup.fillMode = kCAFillModeForwards
    }
    
    private func readCameraStatus() {
        // float3 pos
        // float3 lookat?
        // float3 rot
        // usesParse
        
        // just ignore data
        skip(37)
    }
    
    // MARK: - Light Frame
    private func readLights() {
        self.workingLightAnimationGroup = CAAnimationGroup()
        self.workingLightAnimationGroup.animations = [CAAnimation]()
        self.lightFrameHash = [Int:MMDVMDLightInfo]()

        readOneLightFrame(hasIndex: false)
        
        let lightFrameCount = getUnsignedInt()
        print("lightFrameCount: \(lightFrameCount)")
        for _ in 0..<lightFrameCount {
            readOneLightFrame()
        }
        
        createLightAnimation()

        readLightStatus()
    }
    
    private func readOneLightFrame(hasIndex: Bool = true) {
        var index: Int = -1
        if hasIndex {
            index = Int(getUnsignedInt())
        }

        let info = MMDVMDLightInfo(reader: self)
        if hasIndex {
            self.lightFrameHash[index] = info
        } else {
            self.initialLightFrame = info
        }
    }
    
    private func createLightAnimation() {
        let colorMotion = CAKeyframeAnimation(keyPath: "light.color")
        let directionMotion = CAKeyframeAnimation(keyPath: "transform.quaternion")
        
        colorMotion.values = [AnyObject]()
        directionMotion.values = [AnyObject]()
        
        colorMotion.keyTimes = [NSNumber]()
        directionMotion.keyTimes = [NSNumber]()
        
        self.frameLength = 0
        self.addLightMotionRecursive(info: self.initialLightFrame,
                                     colorMotion: colorMotion,
                                     directionMotion: directionMotion)
        
        let duration = Double(self.frameLength) / self.fps
        print("light frameLength: \(self.frameLength)")
        
        for motion in [colorMotion, directionMotion] {
            motion.duration = duration
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards
            
            for num in 0..<motion.keyTimes!.count {
                let keyTime: Float = motion.keyTimes![num].floatValue / Float(self.frameLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
            
            self.workingLightAnimationGroup.animations!.append(motion)
        }
        
        /*
        for index in 0..<colorMotion.values!.count {
            let value = colorMotion.values![index]
            let keyTime = colorMotion.keyTimes![index]
            print("color @ keyTime \(keyTime) : \(value)")
        }
         */

        self.workingLightAnimationGroup.duration = duration
        self.workingLightAnimationGroup.usesSceneTimeBase = false
        self.workingLightAnimationGroup.isRemovedOnCompletion = false
        self.workingLightAnimationGroup.fillMode = kCAFillModeForwards

    }

    private func addLightMotionRecursive(
        info: MMDVMDLightInfo,
        colorMotion: CAKeyframeAnimation,
        directionMotion: CAKeyframeAnimation) {
        
        var frameIndex = colorMotion.keyTimes!.count - 1
        
        // the frame number might not be sorted
        while frameIndex >= 0 {
            let k = colorMotion.keyTimes![frameIndex].intValue
            if(k < info.frameNo) {
                break
            }
            
            frameIndex -= 1
        }
        frameIndex += 1

        if(info.frameNo > self.frameLength) {
            self.frameLength = info.frameNo
        }
        let nsFrameNo = NSNumber(integerLiteral: info.frameNo)
        
        colorMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        directionMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        
        colorMotion.values!.insert(info.color, at: frameIndex)
        directionMotion.values!.insert(info.direction, at: frameIndex)
        
        if info.next > 0 {
            if let nextMotion = self.lightFrameHash[info.next] {
                self.addLightMotionRecursive(info: nextMotion,
                                            colorMotion: colorMotion,
                                            directionMotion: directionMotion)
            } else {
                print("error: the light frame index(\(info.next)) doesn't exist.")
            }
        }
    }
    
    private func readLightStatus() {
        // float3 rgb
        // float3 pos
        // byte5 unknown
        
        // just ignore data
        skip(29)
    }
    
    // MARK: - Accessory Frame
    private func readAccessories() {
        print("before accessoryCount pos: \(self._pos)")
        self.accessoryCount = Int(getUnsignedByte())
        self.accessoryNameArray = [String]()
        
        print("accessoryCount: \(self.accessoryCount)")

        for _ in 0..<self.accessoryCount {
            self.accessoryNameArray.append(getString(length: 100)! as String)
        }
        for index in 0..<self.accessoryCount {
            print("[\(index)]: \(self.accessoryNameArray[index])")
        }
        
        if (self.modelCount + self.accessoryCount) > self.substituteModels.count {
            for _ in 0..<(self.modelCount + self.accessoryCount - self.substituteModels.count) {
                self.substituteModels.append(nil)
            }
        }

        self.accessoryFrameHash = [Int:MMDVMDAccessoryInfo]()

        for index in 0..<self.accessoryCount {
            var accessory = MMDNode()
            print("reader pos: \(self._pos)")
            if let m = self.substituteModels[self.modelCount + index] {
                accessory = m
                
                // just skip accessory data
                skip(358)
            } else {
                let no = getUnsignedByte()
                let name = getString(length: 100)
                let path = getString(length: 256)
                
                accessory.name = name as String?
                print("accessory[\(no)]: \(String(describing: name)): \(String(describing: path))")
                
                let filePathMatches = userFilePathPattern.matches(path! as String)
                if let paths = filePathMatches {
                    let replaced = paths[1].replacingOccurrences(of: "\\", with: "/")
                    let newFilePath = self.directoryPath + "/" + replaced
                    print("newFilePath: \(newFilePath)")
                    
                    if let accessoryScene = MMDSceneSource(path: newFilePath) {
                        if let newAccessory = accessoryScene.getModel() {
                            accessory = newAccessory
                        } else {
                            print("can't get accessory data: \(newFilePath)")
                        }
                    } else {
                        print("can't read file: \(newFilePath)")
                    }
                }

                // set the default scale for accessory (x10)
                accessory.scale = SCNVector3Make(10.0, 10.0, 10.0)
                /*
                accessory.filters = [CIFilter]()
                let filter = CIFilter(name: "CIAdditionCompositing")
                if let additive = filter {
                    additive.name = "additive"
                    additive.isEnabled = false
                    accessory.filters!.append(additive)
                }
                let isEnabled = accessory.value(forKeyPath: "filters.additive.isEnabled")
                print("additive.isEnabled: \(isEnabled)")
                */
                let accessoryIndex = Int(getUnsignedByte())
                print("index[\(accessoryIndex)]: \(accessoryNameArray[accessoryIndex])")
            }
            
            readOneAccessoryFrame(hasIndex: false)
            
            let accessoryFrameCount = getUnsignedInt()
            print("accessoryFrameCount: \(accessoryFrameCount)")
            for _ in 0..<accessoryFrameCount {
                readOneAccessoryFrame()
            }
            
            createAccessoryAnimation()
            
            readAccessoryStatus()
            
            self.accessories.append(accessory)
        }
    }
    
    private func readOneAccessoryFrame(hasIndex: Bool = true) {
        var index: Int = 0
        if hasIndex {
            index = Int(getUnsignedInt())
        }

        print("accessory frame index: \(index)")
        let info = MMDVMDAccessoryInfo(reader: self)
        if hasIndex {
            self.accessoryFrameHash[index] = info
        } else {
            self.initialAccessoryFrame = info
        }
    }
    
    private func createAccessoryAnimation() {
        let animation = CAAnimationGroup()
        animation.animations = [CAAnimation]()
        
        let posMotion = CAKeyframeAnimation(keyPath: "position")
        let rotMotion = CAKeyframeAnimation(keyPath: "transform.quaternion")
        let scaleMotion = CAKeyframeAnimation(keyPath: "scale")
        let hiddenMotion = CAKeyframeAnimation(keyPath: "hidden")
        let opacityMotion = CAKeyframeAnimation(keyPath: "opacity")
        let additiveMotion = CAKeyframeAnimation(keyPath: "/Geometry.materials.blendMode")
        let parentMotion = CAKeyframeAnimation(keyPath: "parent.motionParentNode")
        
        
        posMotion.values = [AnyObject]()
        rotMotion.values = [AnyObject]()
        scaleMotion.values = [AnyObject]()
        hiddenMotion.values = [AnyObject]()
        opacityMotion.values = [AnyObject]()
        additiveMotion.values = [AnyObject]()
        parentMotion.values = [AnyObject]()
        
        posMotion.keyTimes = [NSNumber]()
        rotMotion.keyTimes = [NSNumber]()
        scaleMotion.keyTimes = [NSNumber]()
        hiddenMotion.keyTimes = [NSNumber]()
        opacityMotion.keyTimes = [NSNumber]()
        additiveMotion.keyTimes = [NSNumber]()
        parentMotion.keyTimes = [NSNumber]()
        
        self.frameLength = 0
        self.addAccessoryMotionRecursive(info: self.initialAccessoryFrame,
                                         posMotion: posMotion,
                                         rotMotion: rotMotion,
                                         scaleMotion: scaleMotion,
                                         hiddenMotion: hiddenMotion,
                                         opacityMotion: opacityMotion,
                                         additiveMotion: additiveMotion,
                                         parentMotion: parentMotion)
        
        let duration = Double(self.frameLength) / self.fps
        print("accessory frameLength: \(self.frameLength), duration: \(duration)")
        
        for motion in [posMotion, rotMotion, scaleMotion, hiddenMotion, opacityMotion, additiveMotion, parentMotion] {
            motion.duration = duration
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards

            for num in 0..<motion.keyTimes!.count {
                var keyTime = motion.keyTimes![num].floatValue / Float(self.frameLength)
                if self.frameLength <= 0 {
                    keyTime = 0.0
                }
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
        }
        hiddenMotion.calculationMode = kCAAnimationDiscrete
        additiveMotion.calculationMode = kCAAnimationDiscrete
        parentMotion.calculationMode = kCAAnimationDiscrete
        
        for num in 0..<hiddenMotion.keyTimes!.count {
            let keyTime = hiddenMotion.keyTimes![num]
            let value = hiddenMotion.values![num]
            print("isHidden @\(keyTime) : \(value)")
        }
        
        animation.animations!.append(posMotion)
        animation.animations!.append(rotMotion)
        animation.animations!.append(scaleMotion)
        animation.animations!.append(hiddenMotion)
        animation.animations!.append(opacityMotion)
        //animation.animations!.append(additiveMotion)
        //animation.animations!.append(parentMotion)
        animation.duration = duration
        animation.usesSceneTimeBase = false
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        
        var parentEvents = [SCNAnimationEvent]()
        var prevParent: SCNNode? = nil
        
        for index in 0..<parentMotion.keyTimes!.count {
            let keyTime = parentMotion.keyTimes![index].floatValue
            let value = parentMotion.values![index]
            //print("parent keyTime \(keyTime): value \(value)")

            if let mmdParentNode = value as? SCNNode {
                // TODO: implement for playingBackward
                let parentEvent = SCNAnimationEvent(keyTime: CGFloat(keyTime), block: { (animation: SCNAnimationProtocol, animatedObject: Any, playingBackward: Bool) in
                    //print("===== parentEvent: \(keyTime), \(mmdParentNode) =====")
                    if let node = animatedObject as? SCNNode {
                        //print("change parent")
                        if playingBackward {
                            if let parent = prevParent {
                                parent.addChildNode(node)
                            }
                        } else {
                            mmdParentNode.addChildNode(node)
                        }
                        
                        //print(String(format: "<Pointer><Center><callback> readOneAccessoryFrame callback mmdParentNode: %p", mmdParentNode))

                        //print("accessory.transform: \(node.transform)")
                        //print("accessory.presentation.transform: \(node.presentation.transform)")
                    }
                })
                //print(String(format: "<Pointer><Center> readOneAccessoryFrame mmdParentNode: %p", mmdParentNode))

                parentEvents.append(parentEvent)
                prevParent = mmdParentNode
            }
        }
        
        var prevBlendMode: SCNBlendMode! = .alpha
        for index in 0..<additiveMotion.keyTimes!.count {
            let keyTime = additiveMotion.keyTimes![index]
            let value = additiveMotion.values![index] as! SCNBlendMode
            
            let additiveEvent = SCNAnimationEvent(keyTime: CGFloat(keyTime.floatValue), block: { (animation: SCNAnimationProtocol, animatedObject: Any, playingBackward: Bool) in
                
                print("additiveEvent")
                if let node = animatedObject as? SCNNode {
                    if let geometry = node.childNode(withName: "Geometry", recursively: true)?.geometry {
                        print("setValue")
                        var blendMode = value
                        if playingBackward {
                            blendMode = prevBlendMode
                        }
                        if blendMode == .add {
                            print(".add")
                        } else if blendMode == .alpha {
                            print(".alpha")
                        }
                        for material in geometry.materials {
                            material.blendMode = blendMode
                        }
                    }
                }
            })
            parentEvents.append(additiveEvent)
            prevBlendMode = value
        }

        animation.animationEvents = parentEvents
        
        self.accessoryMotions.append(animation)
    }
    
    private func addAccessoryMotionRecursive(
        info: MMDVMDAccessoryInfo,
        posMotion: CAKeyframeAnimation,
        rotMotion: CAKeyframeAnimation,
        scaleMotion: CAKeyframeAnimation,
        hiddenMotion: CAKeyframeAnimation,
        opacityMotion: CAKeyframeAnimation,
        additiveMotion: CAKeyframeAnimation,
        parentMotion: CAKeyframeAnimation) {
        
        var frameIndex = posMotion.keyTimes!.count - 1
        
        // the frame number might not be sorted
        while frameIndex >= 0 {
            let k = posMotion.keyTimes![frameIndex].intValue
            if(k < info.frameNo) {
                break
            }
            
            frameIndex -= 1
        }
        frameIndex += 1
        
        if(info.frameNo > self.frameLength) {
            self.frameLength = info.frameNo
        }
        let nsFrameNo = NSNumber(integerLiteral: info.frameNo)
        
        posMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        rotMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        scaleMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        hiddenMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        opacityMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        additiveMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        parentMotion.keyTimes!.insert(nsFrameNo, at: frameIndex)
        
        posMotion.values!.insert(info.position, at: frameIndex)
        rotMotion.values!.insert(info.rotation, at: frameIndex)
        scaleMotion.values!.insert(info.scale, at: frameIndex)
        hiddenMotion.values!.insert(info.isHidden, at: frameIndex)
        opacityMotion.values!.insert(info.opacity, at: frameIndex)
        additiveMotion.values!.insert(info.additive, at: frameIndex)
        parentMotion.values!.insert(info.parent as Any, at: frameIndex)
        
        if info.next > 0 {
            if let nextMotion = self.accessoryFrameHash[info.next] {
                self.addAccessoryMotionRecursive(info: nextMotion,
                                                 posMotion: posMotion,
                                                 rotMotion: rotMotion,
                                                 scaleMotion: scaleMotion,
                                                 hiddenMotion: hiddenMotion,
                                                 opacityMotion: opacityMotion,
                                                 additiveMotion: additiveMotion,
                                                 parentMotion: parentMotion)
            } else {
                print("error: the accessory frame index(\(info.next)) doesn't exist.")
            }
        }
    }

    private func readAccessoryStatus() {
        // byte opacity?
        // int modelIndex
        // int boneIndex
        // float3 pos
        // float scale
        // float3 rot
        // byte flag1?
        // byte flag2?
        
        print("readAccessoryStatus")
        for i in 0..<38 {
            let data = getUnsignedByte()
            print("\(i): \(data)")
        }
        if(self.version >= 2){
            let data = getUnsignedByte()
            print("38: \(data)")
        }
        
        //skip(39)
    }

    // MARK: - other settings
    
    private func readSettings() {
        let numObjects = self.modelCount + self.accessoryCount
        print("numObjects: \(numObjects), modelCount: \(self.modelCount)")
 
        //skip(27)
        
        let viewFlag = getUnsignedByte()
        
        // wav file
        let usesWav = getUnsignedByte()
        let wavPath = getString(length: 256)
        
        print("usesWav: \(usesWav)")
        print("wavfile: \(String(describing: wavPath))")
        
        // background movie
        let bgMoviePath = getString(length: 256)
        let usesMovie = getUnsignedByte()
        
        print("usesMovie: \(usesMovie)")
        print("bgMoviePath: \(String(describing: bgMoviePath))")
        
        // background image
        let bgImagePath = getString(length: 256)
        let usesImage = getUnsignedByte()
        
        print("usesImage: \(usesImage)")
        print("bgImagePath: \(String(describing: bgImagePath))")
        
        // misc.
        let showInfo = getUnsignedByte()
        let showGrid = getUnsignedByte()
        let shadow = getUnsignedByte()
        print("\(showInfo), \(showGrid), \(shadow)")
        skip(3) // ?
        
        let screenCapture = getUnsignedByte()
        skip(7) // ?
        
        let shadowColor = getFloat() // ?
        
        skip(numObjects)
        
        skip(4 * self.modelCount)
        //skip(52) // ?
        
        skip(62) // ?
        
        let usesPhysics = getUnsignedByte()
        let gravity = getFloat()
        var noise: Float = 0.0
        if self.version == 1 {
            noise = getFloat()
        }
        let gravityX = getFloat()
        let gravityY = getFloat()
        let gravityZ = getFloat()
        
        print("gravity: \(gravity) @ (\(gravityX), \(gravityY), \(gravityZ))")
        
        //let usesPhysicsNoise = getUnsignedByte()
        //print("usesPhysicsNoise: \(usesPhysicsNoise)")
        skip(24) // ?
        
        skip(self.modelCount)
        
        skip(5)
        
        /*
        let selfShadowFrameCount = getUnsignedInt()
        print("selfShadowFrameCount: \(selfShadowFrameCount)")
        for _ in 0..<selfShadowFrameCount {
            skip(1)
            skip(self.modelCount)
            skip(21)
        }
        
        skip(1)
        let edgeR = getFloat()
        let edgeG = getFloat()
        let edgeB = getFloat()
        skip(1)
        print("edgeColor: \(edgeR), \(edgeG), \(edgeB)")
        
        let usesBlackBackground = getUnsignedByte()
        print("usesBlackBackground: \(usesBlackBackground)")
 */
    }
    
    private func setupScene() {
        print("setupScene")
        
        // camera
        let cameraNode = MMDCameraNode()
        //cameraNode.addAnimation(self.workingCameraAnimationGroup, forKey: "motion")
        cameraNode.prepareAnimation(self.workingCameraAnimationGroup, forKey: "motion")
        cameraNode.playPreparedAnimation(forKey: "motion")
        cameraNode.camera?.automaticallyAdjustsZRange = true
        
        self.workingScene.rootNode.addChildNode(cameraNode)
        
        
        // light
        /*
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .directional
        lightNode.light!.castsShadow = true
        //lightNode.light!.shadowMode = .deferred
        lightNode.addAnimation(self.workingLightAnimationGroup, forKey: "motion")
        lightNode.name = "MMDLight"
         */
        let directionalLightNode = SCNNode()
        directionalLightNode.light = SCNLight()
        directionalLightNode.light!.type = .directional
        directionalLightNode.light!.castsShadow = true
        //lightNode.light!.shadowMode = .deferred
//        directionalLightNode.addAnimation(self.workingLightAnimationGroup, forKey: "motion")
        directionalLightNode.name = "MMDLight"
        self.workingScene.rootNode.addChildNode(directionalLightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.intensity = 1000
        ambientLightNode.light!.castsShadow = false
        ambientLightNode.addAnimation(self.workingLightAnimationGroup, forKey: "motion")
        ambientLightNode.name = "MMDAmbientLight"
        directionalLightNode.addChildNode(ambientLightNode)
        
        // model and motion
        print("numModels: \(self.models.count)")
        print("numMotions: \(self.motions.count)")
        
        for index in 0..<self.models.count {
            let model = self.models[index]
            let motion = self.motions[index]
            
            print("model[\(index)]: \(String(describing: model.name)) added")

            //model.addAnimation(motion, forKey: "motion")
            model.prepareAnimation(motion, forKey: "motion")
            model.playPreparedAnimation(forKey: "motion")
            self.workingScene.rootNode.addChildNode(model)
        }
        
        // accessory
        for index in 0..<self.accessories.count {
            let accessory = self.accessories[index]
            let motion = self.accessoryMotions[index]
            
            //accessory.addAnimation(motion, forKey: "motion")
            accessory.prepareAnimation(motion, forKey: "motion")
            accessory.playPreparedAnimation(forKey: "motion")
            
            /*
            accessory.filters = [CIFilter]()
            let filter = CIFilter(name: "CIAdditionCompositing")
            if let additive = filter {
                additive.name = "additive"
                accessory.filters!.append(additive)
            }
            */
            
            self.workingScene.rootNode.addChildNode(accessory)
        }
    }
    
    private func getPascalString() -> NSString {
        let strlen = Int(getUnsignedByte())
        if let str = getString(length: strlen) {
            return str
        }
        
        return ""
    }
}

#endif
