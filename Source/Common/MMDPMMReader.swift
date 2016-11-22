//
//  MMDPMMReader.swift
//  MMDSceneKit
//
//  Created by magicien on 11/17/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit

class MMDPMMReader: MMDReader {
    private var workingScene: SCNScene! = nil
    
    // MARK: PMM header data
    private var pmmMagic: String! = ""
    private var version: Int = 0
    
    private var boneCount: Int = 0
    private var boneNameArray: [String]! = nil
    
    private var faceCount: Int = 0
    private var faceNameArray: [String]! = nil
    
    private var ikCount: Int = 0
    private var ikIndexArray: [Int]! = nil
    
    private var parentCount: Int = 0
    
    private var accessoryCount: Int = 0
    private var accessoryNameArray: [String]! = nil
    
    private var modelCount: Int = 0
    private var models = [MMDNode]()
    private var workingModel: MMDNode! = nil

    /**
     
     */
    static func getScene(_ data: Data, directoryPath: String! = "") -> SCNScene? {
        let reader = MMDPMMReader(data: data, directoryPath: directoryPath)
        let scene = reader.loadPMMFile()
        
        return scene
    }
    
    // MARK: - Loading PMM File
    /**
     * load .pmm file
     * - return:
     */
    private func loadPMMFile() -> SCNScene? {
        // initialize working variables
        self.workingScene = SCNScene()
        
        self.pmmMagic = ""
        self.version = 0
        
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
            print("skip 1 more byte")
            skip(1)
        }
    }

    private func readModels() {
        self.modelCount = Int(getUnsignedByte())
        print("modelCount: \(self.modelCount)")
        
        if self.version == 1 {
            for _ in 0..<self.modelCount {
                let text = getString(length: 20)
                print("\(text)")
            }
        }
        
        for modelNo in 0..<self.modelCount {
            let model = MMDNode()
            self.workingModel = model
            
            let no = getUnsignedByte()
            
            if version == 1 {
                model.name = getString(length: 20) as! String
            } else {
                model.name = getPascalString() as String
                //model.englishName = getPascalString() as String
                let englishName = getPascalString() as String
            }
            
            let filePath = getString(length: 256)
            skip(1) // unknown flag
            
            print("\(model.name): filePath: \(filePath)")

            if self.version > 1 {
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
                getUnsignedByte() // the frame is shown if it's true...
            }
            
            skip(4) // unknown
            
            let lastFrame = getUnsignedInt()
            print("lastFrame: \(lastFrame)")
            
            readBoneFrames()
            readFaceFrames()
            readIKFrames()
            
            readBoneStatus()
            readFaceStatus()
            readIKStatus()
            readParentStatus()
            
            skip(7)
            
            self.models.append(model)
        }
    }
    
    private func readBone() {
        self.boneCount = Int(getUnsignedInt())
        print("boneCount: \(boneCount)")
        
        self.boneNameArray = [String]()
        for _ in 0..<self.boneCount {
            self.boneNameArray.append(getPascalString() as String)
        }
        
        for boneName in self.boneNameArray {
            print("    bone: \(boneName)")
        }
    }
    
    private func readFace() {
        self.faceCount = Int(getUnsignedInt())
        self.faceNameArray = [String]()
        for _ in 0..<self.faceCount {
            self.faceNameArray.append(getPascalString() as String)
        }
        
        for faceName in self.faceNameArray {
            print("    face: \(faceName)")
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
    
    private func readBoneFrames() {
        for _ in 0..<self.boneCount {
            readOneBoneFrame(hasIndex: false)
        }
        
        let boneFrameCount = getUnsignedInt()
        for _ in 0..<boneFrameCount {
            readOneBoneFrame()
        }
    }
    
    private func readOneBoneFrame(hasIndex: Bool = true) {
        var index: UInt32 = 0
        if hasIndex {
            index = getUnsignedInt()
        }
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
        
        skip(1) // unknown
        
        let isSelected = getUnsignedByte()
        
        print("boneFrame: frameNo: \(frameNo)")
    }
    
    private func readFaceFrames() {
        for _ in 0..<self.faceCount {
            readOneFaceFrame(hasIndex: false)
        }
        let faceFrameCount = getUnsignedInt()
        for _ in 0..<faceFrameCount {
            readOneFaceFrame()
        }
    }
    
    private func readOneFaceFrame(hasIndex: Bool = true) {
        var index: UInt32 = 0
        if hasIndex {
            index = getUnsignedInt()
        }
        let frameNo = getUnsignedInt()
        let prev = getUnsignedInt()
        let next = getUnsignedInt()
        
        let weight = getFloat()
        let selected = getUnsignedByte()
        
        //print("readOneFaceFrame: selected: \(selected)")
        print("faceFrame: frameNo: \(frameNo)")
    }
    
    private func readIKFrames() {
        //for _ in 0..<self.ikCount {
            readOneIKFrame(hasIndex: false)
        //}
        
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
                let parent1 = getUnsignedInt()
                let parent2 = getUnsignedInt()
        }
        
        let isSelected = getUnsignedByte()
        
        print("IK Frame: frameNo: \(frameNo)")
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
    
    private func readCameras() {
        readOneCameraFrame(hasIndex: false)
        
        let cameraFrameCount = getUnsignedInt()
        print("cameraFrameCount: \(cameraFrameCount)")
        for _ in 0..<cameraFrameCount {
            readOneCameraFrame()
        }
        
        readCameraStatus()
    }
    
    private func readOneCameraFrame(hasIndex: Bool = true) {
        var dataIndex: Int = -1
        if hasIndex {
            dataIndex = Int(getUnsignedInt())
        }
        let frameNo = getUnsignedInt()
        let prev = getUnsignedInt()
        let next = getUnsignedInt()
        let distance = getFloat()
        let posX = getFloat()
        let posY = getFloat()
        let posZ = getFloat()
        let rotX = getFloat()
        let rotY = getFloat()
        let rotZ = getFloat()

        var rotW: Float = 0.0
        var followModelIndex = -1
        var followBoneIndex: UInt32 = 0
        
        if version == 1 {
            rotW = getFloat()
        } else if version == 2 {
            followModelIndex = Int(getInt())
            followBoneIndex = getUnsignedInt()
        }
        
        print("camera frame: \(frameNo)")
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
    }
    
    private func readCameraStatus() {
        // float3 pos
        // float3 lookat?
        // float3 rot
        // usesParse
        
        // just ignore data
        skip(37)
    }
    
    private func readLights() {
        readOneLightFrame(hasIndex: false)
        
        let lightFrameCount = getUnsignedInt()
        print("lightFrameCount: \(lightFrameCount)")
        for _ in 0..<lightFrameCount {
            readOneLightFrame()
        }

        readLightStatus()
    }
    
    private func readOneLightFrame(hasIndex: Bool = true) {
        var dataIndex: Int = -1
        if hasIndex {
            dataIndex = Int(getUnsignedInt())
        }
        let frameNo = getUnsignedInt()
        let prev = getUnsignedInt()
        let next = getUnsignedInt()
        
        print("light frameNo: \(frameNo)")
        
        skip(25)
    }
    
    private func readLightStatus() {
        // float3 rgb
        // float3 pos
        // byte5 unknown
        
        // just ignore data
        skip(29)
    }
    
    private func readAccessories() {
        self.accessoryCount = Int(getUnsignedByte())
        self.accessoryNameArray = [String]()
        
        print("accessoryCount: \(self.accessoryCount)")

        for _ in 0..<self.accessoryCount {
            self.accessoryNameArray.append(getString(length: 100) as! String)
        }
        
        for _ in 0..<self.accessoryCount {
            let no = getUnsignedByte()
            let name = getString(length: 100)
            let path = getString(length: 256)
            
            print("accessory[\(no)]: \(name): \(path)")
            
            skip(94) // ?
        }
    }
    
    private func readSettings() {
        skip(27)
        
        let viewFlag = getUnsignedByte()
        
        // wav file
        let usesWav = getUnsignedByte()
        let wavPath = getString(length: 256)
        
        print("usesWav: \(usesWav)")
        print("wavfile: \(wavPath)")
        
        // background movie
        let bgMoviePath = getString(length: 256)
        let usesMovie = getUnsignedByte()
        
        print("usesMovie: \(usesMovie)")
        print("bgMoviePath: \(bgMoviePath)")
        
        // background image
        let bgImagePath = getString(length: 256)
        let usesImage = getUnsignedByte()
        
        print("usesImage: \(usesImage)")
        print("bgImagePath: \(bgImagePath)")
        
        // misc.
        let showInfo = getUnsignedByte()
        let showGrid = getUnsignedByte()
        let shadow = getUnsignedByte()
        print("\(showInfo), \(showGrid), \(shadow)")
        skip(3) // ?
        
        let screenCapture = getUnsignedByte()
        skip(7) // ?
        
        let shadowColor = getFloat() // ?
        
        let numObjects = self.modelCount + self.accessoryCount
        skip(numObjects)
        
        skip(4 * self.modelCount)
        skip(52) // ?
        
        let usesPhysics = getUnsignedByte()
        let gravity = getFloat()
        let gravityX = getFloat()
        let gravityY = getFloat()
        let gravityZ = getFloat()
        
        print("gravity: \(gravity) @ (\(gravityX), \(gravityY), \(gravityZ))")
        
        let usesPhysicsNoise = getUnsignedByte()
        print("usesPhysicsNoise: \(usesPhysicsNoise)")
        skip(20) // ?
        
        skip(self.modelCount)
        
        skip(5)
        
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
    }
    
    private func getPascalString() -> NSString {
        let strlen = Int(getUnsignedByte())
        if let str = getString(length: strlen) {
            return str
        }
        
        return ""
    }
}
