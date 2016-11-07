//
//  MMDPMXReader.swift
//  MMDSceneKit
//
//  Created by magicien on 1/2/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit

class MMDPMXReader: MMDReader {
    fileprivate var workingNode: MMDNode! = nil
    
    // MARK: PMD header data
    fileprivate var pmxMagic: String! = ""
    fileprivate var version: Float = 0.0
    fileprivate var encoding: String.Encoding = String.Encoding.utf8
    fileprivate var numUV: Int = 1
    fileprivate var indexSize: Int = 1
    fileprivate var textureIndexSize: Int = 1
    fileprivate var materialIndexSize: Int = 1
    fileprivate var boneIndexSize: Int = 1
    fileprivate var morphIndexSize: Int = 1
    fileprivate var physicsBodyIndexSize: Int = 1
    fileprivate var modelName: String! = ""
    fileprivate var englishModelName: String! = ""
    fileprivate var comment: String! = ""
    fileprivate var englishComment: String! = ""
    
    // MARK: vertex data
    fileprivate var vertexCount = 0
    fileprivate var vertexArray: [Float32]! = nil
    fileprivate var normalArray: [Float32]! = nil
    fileprivate var texcoordArray: [Float32]! = nil
    fileprivate var boneIndicesArray: [Int]! = nil
    fileprivate var boneWeightsArray: [Float32]! = nil
    fileprivate var edgeArray: [Float32]! = nil
    
    // MARK: index data
    fileprivate var indexCount = 0
    fileprivate var indexArray: [Int]! = nil
    fileprivate var separatedIndexArray: [[Int]]! = nil
    
    // MARK: texture data
    fileprivate var textureCount = 0
    #if os(iOS) || os(watchOS)
        fileprivate var textureArray: [UIImage]! = nil
    #elseif os(OSX)
        private var textureArray: [NSImage]! = nil
    #endif
    
    // MARK: material data
    fileprivate var materialCount = 0
    fileprivate var materialArray: [SCNMaterial]! = nil
    fileprivate var materialIndexCountArray: [Int]! = nil
    fileprivate var materialShapeArray: [SCNGeometryPrimitiveType]! = nil
    
    // MARK: bone data
    fileprivate var boneCount = 0
    fileprivate var boneArray: [MMDNode]! = nil
    fileprivate var boneInverseMatrixArray: [NSValue]! = nil
    fileprivate var rootBone: MMDNode! = nil
    fileprivate var boneHash: [String:MMDNode]! = nil
    
    // MARK: IK data
    fileprivate var ikCount = 0
    fileprivate var ikArray: [MMDNode]! = nil
    
    // MARK: face data
    fileprivate var faceCount = 0
    fileprivate var faceIndexArray: [Int]! = nil
    fileprivate var faceNameArray: [String]! = nil
    fileprivate var faceVertexArray: [[Float32]]! = nil
    
    // MARK: display info data
    fileprivate var faceDisplayCount = 0
    fileprivate var boneDisplayNameCount = 0
    fileprivate var boneDisplayCount = 0
    
    // MARK: physics body data
    fileprivate var physicsBodyCount = 0
    fileprivate var physicsBodyArray: [SCNPhysicsBody]! = nil
    
    // MARK: geometry data
    fileprivate var vertexSource: SCNGeometrySource! = nil
    fileprivate var normalSource: SCNGeometrySource! = nil
    fileprivate var texcoordSource: SCNGeometrySource! = nil
    fileprivate var elementArray: [SCNGeometryElement]! = nil
    fileprivate var separatedIndexData: [Data]! = nil
    
    /**
     */
    static func getNode(_ data: Data, directoryPath: String! = "") -> MMDNode? {
        let reader = MMDPMXReader(data: data, directoryPath: directoryPath)
        let node = reader.loadPMXFile()
        
        return node
    }
    
    // MARK: - Loading PMX File
    fileprivate func loadPMXFile() -> MMDNode? {
        // initialize working variables
        self.workingNode = MMDNode()
        
        self.pmxMagic = ""
        self.version = 0.0
        self.modelName = ""
        self.englishModelName = ""
        self.comment = ""
        self.englishComment = ""
        
        self.vertexCount = 0
        self.vertexArray = [Float32]()
        self.normalArray = [Float32]()
        self.texcoordArray = [Float32]()
        self.boneIndicesArray = [Int]()
        self.boneWeightsArray = [Float32]()
        self.edgeArray = [Float32]()
        
        self.indexCount = 0
        self.indexArray = [Int]()
        self.separatedIndexArray = [[Int]]()
        
        self.materialCount = 0
        self.materialArray = [SCNMaterial]()
        self.materialIndexCountArray = [Int]()
        self.materialShapeArray = [SCNGeometryPrimitiveType]()
        
        #if os(iOS) || os(watchOS)
            self.textureArray = [UIImage]()
        #elseif os(OSX)
            self.textureArray = [NSImage]()
        #endif
        
        self.boneCount = 0
        self.boneArray = [MMDNode]()
        self.boneHash = [String:MMDNode]()
        self.boneInverseMatrixArray = [NSValue]()
        self.rootBone = MMDNode()
        
        self.ikCount = 0
        self.ikArray = [MMDNode]()
        
        self.physicsBodyCount = 0
        self.physicsBodyArray = [SCNPhysicsBody]()
        
        self.faceCount = 0
        self.faceIndexArray = [Int]()
        self.faceNameArray = [String]()
        self.faceVertexArray = [[Float32]]()
        
        self.elementArray = [SCNGeometryElement]()
        
        // read contents of file
        self.readPMXHeader()
        if(self.pmxMagic != "PMX ") {
            print("file is in the wrong format")
            // file is in the wrong format
            return nil
        }
        
        // read basic data
        self.readVertex()
        self.readIndex()
        self.readTexture()
        self.readMaterial()
        self.readBone()
        //self.readIK()
        self.readFace()
        self.readDisplayInfo()
        
        // create geometry for shader
        self.createGeometry()
        //self.createFaceMorph()
        
        self.readPhysicsBody()
        self.readConstraint()
        
        return self.workingNode
    }
    
    fileprivate func getTextBuffer() -> NSString {
        let strlen = Int(getUnsignedInt())
//        return getString(strlen, encoding: self.encoding)!

        let str = getString(strlen, encoding: self.encoding)!
        
        //print("getTextBuffer: \(str)")
        
        return str
    }
    
    /**
     read PMX header data
     */
    fileprivate func readPMXHeader() {
        self.pmxMagic = String(getString(4)!)
        print("pmxMagic: \(pmxMagic)") // suppose to be "PMX "
        self.version = Float(getFloat())
        
        let numData = getUnsignedByte() // suppose to be 8
        
        let encodingNo = getUnsignedByte()
        switch(encodingNo) {
        case 0:
            self.encoding = String.Encoding.utf16LittleEndian
        case 1:
            self.encoding = String.Encoding.utf8
        default:
            print("unknown encoding number: \(encodingNo)")
        }
        
        self.numUV = Int(getUnsignedByte())
        self.indexSize = Int(getUnsignedByte())
        self.textureIndexSize = Int(getUnsignedByte())
        self.materialIndexSize = Int(getUnsignedByte())
        self.boneIndexSize = Int(getUnsignedByte())
        self.morphIndexSize = Int(getUnsignedByte())
        self.physicsBodyIndexSize = Int(getUnsignedByte())
        
        self.modelName = getTextBuffer() as String
        self.englishModelName = getTextBuffer() as String
        self.comment = getTextBuffer() as String
        self.englishComment = getTextBuffer() as String
    }
    
    /**
     read PMX vertex data
     */
    fileprivate func readVertex() {
        self.vertexCount = Int(getInt())
        
        for _ in 0..<self.vertexCount {
            self.vertexArray.append(getFloat())
            self.vertexArray.append(getFloat())
            self.vertexArray.append(-getFloat())
            
            self.normalArray.append(getFloat())
            self.normalArray.append(getFloat())
            self.normalArray.append(-getFloat())
            
            self.texcoordArray.append(getFloat())
            self.texcoordArray.append(getFloat())
            
            for _ in 0..<self.numUV {
                // FIXME: use additional UV
                getFloat()
                getFloat()
                getFloat()
                getFloat()
            }
            
            let weightType = getUnsignedByte()
            var weight1: Float = 0.0
            var weight2: Float = 0.0
            var weight3: Float = 0.0
            var weight4: Float = 0.0
            var boneNo1 = 0
            var boneNo2 = 0
            var boneNo3 = 0
            var boneNo4 = 0
            
            var noBone = 0
            switch(self.boneIndexSize) {
            case 1:
                noBone = Int(0xFF)
            case 2:
                noBone = Int(0xFFFF)
            case 4:
                //noBone = Int(0xFFFFFFFF)
                noBone = -1 // FIXME:
            default: break
                // unknown size
            }
            
            switch(weightType) {
            case 0: // BDEF1
                boneNo1 = getIntOfLength(self.boneIndexSize)
                weight1 = 1.0
            case 1: // BDEF2
                boneNo1 = getIntOfLength(self.boneIndexSize)
                boneNo2 = getIntOfLength(self.boneIndexSize)
                weight1 = getFloat()
                weight2 = 1.0 - weight1
            case 2: // BDEF4
                boneNo1 = getIntOfLength(self.boneIndexSize)
                boneNo2 = getIntOfLength(self.boneIndexSize)
                boneNo3 = getIntOfLength(self.boneIndexSize)
                boneNo4 = getIntOfLength(self.boneIndexSize)
                weight1 = getFloat()
                weight2 = getFloat()
                weight3 = getFloat()
                weight4 = getFloat()
            case 3: // SDEF
                boneNo1 = getIntOfLength(self.boneIndexSize)
                boneNo2 = getIntOfLength(self.boneIndexSize)
                weight1 = getFloat()
                weight2 = 1.0 - weight1
                
                // FIXME: use SDEF-C
                getFloat()
                getFloat()
                getFloat()
                
                // FIXME: use SDEF-R0
                getFloat()
                getFloat()
                getFloat()
                
                // FIXME: use SDEF-R1
                getFloat()
                getFloat()
                getFloat()
            case 4: // QDEF
                boneNo1 = getIntOfLength(self.boneIndexSize)
                boneNo2 = getIntOfLength(self.boneIndexSize)
                boneNo3 = getIntOfLength(self.boneIndexSize)
                boneNo4 = getIntOfLength(self.boneIndexSize)
                weight1 = getFloat()
                weight2 = getFloat()
                weight3 = getFloat()
                weight4 = getFloat()
            default:
                // unknown type
                break
            }
            
            if boneNo1 == noBone {
                boneNo1 = 0
                weight1 = 0
            }
            if boneNo2 == noBone {
                boneNo2 = 0
                weight2 = 0
            }
            if boneNo3 == noBone {
                boneNo3 = 0
                weight3 = 0
            }
            if boneNo4 == noBone {
                boneNo4 = 0
                weight4 = 0
            }
            
            // the first weight must not be 0 in SceneKit...
            if weight1 == 0.0 {
                if weight2 != 0.0 {
                    self.boneIndicesArray.append(boneNo2)
                    self.boneIndicesArray.append(boneNo1)
                    self.boneIndicesArray.append(boneNo3)
                    self.boneIndicesArray.append(boneNo4)
                    
                    self.boneWeightsArray.append(weight2)
                    self.boneWeightsArray.append(weight1)
                    self.boneWeightsArray.append(weight3)
                    self.boneWeightsArray.append(weight4)
                } else if weight3 != 0.0 {
                    self.boneIndicesArray.append(boneNo3)
                    self.boneIndicesArray.append(boneNo1)
                    self.boneIndicesArray.append(boneNo2)
                    self.boneIndicesArray.append(boneNo4)
                    
                    self.boneWeightsArray.append(weight3)
                    self.boneWeightsArray.append(weight1)
                    self.boneWeightsArray.append(weight2)
                    self.boneWeightsArray.append(weight4)
                } else if weight4 != 0.0 {
                    self.boneIndicesArray.append(boneNo4)
                    self.boneIndicesArray.append(boneNo1)
                    self.boneIndicesArray.append(boneNo2)
                    self.boneIndicesArray.append(boneNo3)
                    
                    self.boneWeightsArray.append(weight4)
                    self.boneWeightsArray.append(weight1)
                    self.boneWeightsArray.append(weight2)
                    self.boneWeightsArray.append(weight3)
                } else {
                    // bad data definition
                    print("bad data definition: all bone weights are 0.")
                }
            } else {
                self.boneIndicesArray.append(boneNo1)
                self.boneIndicesArray.append(boneNo2)
                self.boneIndicesArray.append(boneNo3)
                self.boneIndicesArray.append(boneNo4)
                
                self.boneWeightsArray.append(weight1)
                self.boneWeightsArray.append(weight2)
                self.boneWeightsArray.append(weight3)
                self.boneWeightsArray.append(weight4)
            }
            
            self.edgeArray.append(getFloat())
        }
    }
    
    /**
     read PMX index data
     */
    fileprivate func readIndex() {
        self.indexCount = Int(getUnsignedInt())
        
        for _ in 0..<self.indexCount {
            self.indexArray.append(getIntOfLength(self.indexSize))
        }
    }

    /**
     read PMX texture data
     */
    fileprivate func readTexture() {
        self.textureCount = Int(getUnsignedInt())
        
        for _ in 0..<self.textureCount {
            let textureFile = getTextBuffer()
            let fileName = (self.directoryPath as NSString).appendingPathComponent(String(textureFile))

            print("***** textureName: \(textureFile) *****")
            
            #if os(iOS) || os(watchOS)
                var image = UIImage(contentsOfFile: fileName as String)
                if image == nil {
                    image = UIImage()
                }
            #elseif os(OSX)
                var image = NSImage(contentsOfFile: fileName as String)
                if image == nil {
                    image = NSImage()
                }
            #endif
            
            self.textureArray.append(image!)
        }
    }
    
    /**
     read PMX material data
     */
    fileprivate func readMaterial() {
        self.materialCount = Int(getUnsignedInt())
        
        var indexPos = 0

        for _ in 0..<self.materialCount {
            let material = SCNMaterial()
            material.name = getTextBuffer() as String
            
            let englishName = getTextBuffer()
            
            #if os(iOS) || os(watchOS)
                
                material.diffuse.contents = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: getFloat())
                material.specular.contents = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: 1.0)
                material.shininess = CGFloat(getFloat())
                material.ambient.contents = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: 1.0)
                //material.emission.contents = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)

                let bitFlag = getUnsignedByte()
                let edgeColor = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: getFloat())

            #elseif os(OSX)

                material.diffuse.contents = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: CGFloat(getFloat()))
                material.specular.contents = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: 1.0)
                material.shininess = CGFloat(getFloat())
                material.ambient.contents = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: 1.0)
                //material.emission.contents = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
                
                let bitFlag = getUnsignedByte()
                let edgeColor = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: CGFloat(getFloat()))
                
            #endif

            let noCulling = ((bitFlag & 0x01) != 0)
            let floorShadow = ((bitFlag & 0x02) != 0)
            let shadowMap = ((bitFlag & 0x04) != 0)
            let selfShadow = ((bitFlag & 0x08) != 0)
            let drawEdge = ((bitFlag & 0x10) != 0)
            let vertexColor = ((bitFlag & 0x20) != 0)
            let drawPoint = ((bitFlag & 0x40) != 0)
            let drawLine = ((bitFlag & 0x80) != 0)
            
            let edgeSize = getFloat()
            let textureNo = getIntOfLength(self.textureIndexSize)
            let sphereTextureNo = getIntOfLength(self.textureIndexSize)
            let sphereMode = getUnsignedByte()
            let toonFlag = getUnsignedByte()
            var toonTextureNo = 0
            
            if textureNo < self.textureArray.count {
                let texture = self.textureArray[textureNo]
                material.diffuse.contents = texture
            }
            
            if toonFlag == 0 {
                toonTextureNo = getIntOfLength(self.textureIndexSize)
            } else if toonFlag == 1 {
                toonTextureNo = Int(getUnsignedByte())
            } else {
                // unknown flag
            }
            
            if noCulling {
                material.isDoubleSided = true
            } else {
                material.isDoubleSided = false
            }
            
            // FIXME: use floorShadow, shadowMap property
            // FIXME: use drawEdge property
            // FIXME: use vertexColor

            var shape: SCNGeometryPrimitiveType = .triangles
            if drawPoint {
                shape = .point
            } else if drawLine {
                shape = .line
            } else {
                shape = .triangles
            }
            self.materialShapeArray.append(shape)
            
            let text = getTextBuffer()
            let materialIndexCount = Int(getUnsignedInt())
            
            // create index data
            let orgArray = Array(self.indexArray[indexPos..<indexPos+materialIndexCount])
            var newArray = [Int]()
            indexPos += materialIndexCount
            
            var arrayPos = 0
            var newIndexCount = 0
            if shape == .point {
                while arrayPos < materialIndexCount {
                    let index1 = orgArray[arrayPos + 0]
                    let index2 = orgArray[arrayPos + 1]
                    let index3 = orgArray[arrayPos + 2]
                    
                    if index1 == index2 && index2 == index3 {
                        newArray.append(index1)
                        
                        newIndexCount += 1
                    } else {
                        newArray.append(index1)
                        newArray.append(index2)
                        newArray.append(index3)
                        
                        newIndexCount += 3
                    }
                    
                    arrayPos += 3
                }
            } else if shape == .line {
                while arrayPos < materialIndexCount {
                    let index1 = orgArray[arrayPos + 0]
                    let index2 = orgArray[arrayPos + 1]
                    let index3 = orgArray[arrayPos + 2]
                    
                    if index1 == index3 {
                        newArray.append(index1)
                        newArray.append(index2)
                        
                        newIndexCount += 1
                    } else {
                        newArray.append(index1)
                        newArray.append(index2)
                        
                        newArray.append(index2)
                        newArray.append(index3)

                        newArray.append(index3)
                        newArray.append(index1)
                        
                        newIndexCount += 3
                    }
                    
                    arrayPos += 3
                }
            } else if shape == .triangles {
                while arrayPos < materialIndexCount {
                    let index1 = orgArray[arrayPos + 0]
                    let index2 = orgArray[arrayPos + 1]
                    let index3 = orgArray[arrayPos + 2]
                    
                    newArray.append(index1)
                    newArray.append(index3)
                    newArray.append(index2)
                    
                    newIndexCount += 1
                    arrayPos += 3
                }
            }
            
            self.materialIndexCountArray.append(newIndexCount)
            self.materialArray.append(material)
            self.separatedIndexArray.append(newArray)
        }
    }
    
    /**
     read PMX bone data
     */
    fileprivate func readBone() {
        var bonePositionArray = [SCNVector3]()
        var parentNoArray = [Int]()
        var ikTargetNoArray = [Int]()
        
        self.boneCount = Int(getUnsignedInt())
        
        self.rootBone.position = SCNVector3Make(0, 0, 0)
        self.rootBone.name = "rootBone"
        
        for index in 0..<self.boneCount {
            let boneNode = MMDNode()
            self.boneArray.append(boneNode)
        }
        
        for index in 0..<self.boneCount {
            let boneNode = self.boneArray[index]
            
            boneNode.name = getTextBuffer() as String
            let englishName = getTextBuffer()
            
            #if os(iOS) || os(watchOS)
                let x = getFloat()
                let y = getFloat()
                let z = -getFloat()
            #elseif os(OSX)
                let x = CGFloat(getFloat())
                let y = CGFloat(getFloat())
                let z = CGFloat(-getFloat())
            #endif
            
            let position = SCNVector3Make(x, y, z)
            bonePositionArray.append(position)
            
            parentNoArray.append(getIntOfLength(self.boneIndexSize))
            let level = getInt()
            let flags = getUnsignedShort()
            
            let hasChildBoneIndex = ((flags & 0x0001) != 0)
            let isRotatable = ((flags & 0x0002) != 0)
            let isMovable = ((flags & 0x0004) != 0)
            let isVisible = ((flags & 0x0008) != 0)
            let isControllable = ((flags & 0x0010) != 0)
            let isIKBone = ((flags & 0x0020) != 0)
            let isLocalValue = ((flags & 0x0080) != 0)
            let hasRotationValue = ((flags & 0x0100) != 0)
            let hasTranslationValue = ((flags & 0x0200) != 0)
            let hasFixAxis = ((flags & 0x0400) != 0)
            let hasLocalAxis = ((flags & 0x0800) != 0)
            let isDeformable = ((flags & 0x1000) != 0)
            let hasDeformableParent = ((flags & 0x2000) != 0)
            
            if hasChildBoneIndex {
                let childBoneNo = getIntOfLength(self.boneIndexSize)
            } else {
                getFloat()
                getFloat()
                getFloat()
            }
            
            if hasRotationValue {
                let boneIndex = getIntOfLength(self.boneIndexSize)
                let rate = getFloat()
            }
            
            if hasTranslationValue {
                let boneIndex = getIntOfLength(self.boneIndexSize)
                let rate = getFloat()
            }
            
            if hasFixAxis {
                let x = getFloat()
                let y = getFloat()
                let z = getFloat()
            }
            
            if hasLocalAxis {
                let xAxisX = getFloat()
                let xAxisY = getFloat()
                let xAxisZ = getFloat()
                
                let zAxisX = getFloat()
                let zAxisY = getFloat()
                let zAxisZ = getFloat()
            }
            
            if hasDeformableParent {
                let parentBoneKey = getInt()
            }
            
            if isIKBone {
                let targetBoneNo = getIntOfLength(self.boneIndexSize)
                let targetBone = self.boneArray[targetBoneNo]
                
                
                let ikLoopCount = getInt()
                let ikLimit = getFloat()
                let linkCount = getInt()
                
                var linkBoneNoArray = [Int]()
                
                for _ in 0..<linkCount {
                    let linkBoneNo = getIntOfLength(self.boneIndexSize)
                    linkBoneNoArray.append(linkBoneNo)
                    
                    let limitFlag = getUnsignedByte()
                    if limitFlag == 1 {
                        // TODO: constraint
                        let minX = getFloat()
                        let minY = getFloat()
                        let minZ = getFloat()
                        let maxX = getFloat()
                        let maxY = getFloat()
                        let maxZ = getFloat()
                    }
                }
                
                let chainRootNode = self.boneArray[ linkBoneNoArray[linkCount-1] ]
                let constraint = SCNIKConstraint.inverseKinematicsConstraint(chainRootNode: chainRootNode)
                
                if targetBone.constraints == nil {
                    targetBone.constraints = [SCNConstraint]()
                }
                targetBone.constraints!.append(constraint)
                
            } else {
                ikTargetNoArray.append(-1)
            }
        }
        
        // set parent node
        var noParent = 0
        if self.boneIndexSize == 1 {
            noParent = 0xFF
        } else if self.boneIndexSize == 2 {
            noParent = 0xFFFF
        } else if self.boneIndexSize == 4 {
            //noParent = 0xFFFFFFFF
            noParent = -1 // FIXME: 
        }
        
        for index in 0..<self.boneCount {
            let bone = self.boneArray[index]
            let parentNo = parentNoArray[index]
            let bonePos = bonePositionArray[index]
            
            if (parentNo != noParent) {
                boneArray[parentNo].addChildNode(bone)
                
                let parentPos = bonePositionArray[parentNo]
                bone.position.x = bonePos.x - parentPos.x
                bone.position.y = bonePos.y - parentPos.y
                bone.position.z = bonePos.z - parentPos.z
            } else {
                self.rootBone.addChildNode(bone)
                bone.position = bonePos
            }
        }
        
        // calc initial matrix
        for index in 0..<self.boneCount {
            let bonePos = bonePositionArray[index]
            let matrix = SCNMatrix4MakeTranslation(-bonePos.x, -bonePos.y, -bonePos.z)
            
            self.boneInverseMatrixArray.append(NSValue.init(scnMatrix4: matrix))
        }
        
        self.boneArray.append(self.rootBone)
        self.boneInverseMatrixArray.append(NSValue.init(scnMatrix4: SCNMatrix4Identity))
        
        /*
        self.workingNode.position = SCNVector3Make(0, 0, 0)
        self.boneArray.append(self.workingNode)
        self.boneInverseMatrixArray.append(NSValue.init(SCNMatrix4: SCNMatrix4Identity))
        */
        
        // set constarint to knees
        /*
        let kneeConstraint = SCNTransformConstraint(inWorldSpace: false, withBlock: { (node, matrix) -> SCNMatrix4 in
            if let mmdNode = node as? MMDNode {
                return self.calcKneeConstraint(matrix)
            }
            
            return matrix
        })
        
        let leftKnee = self.rootBone.childNodeWithName("左ひざ", recursively: true)
        if leftKnee != nil {
            if leftKnee!.constraints == nil {
                leftKnee!.constraints = [SCNConstraint]()
            }
            leftKnee!.constraints!.append(kneeConstraint)
        }
        
        let rightKnee = self.rootBone.childNodeWithName("右ひざ", recursively: true)
        if rightKnee != nil {
            if rightKnee!.constraints == nil {
                rightKnee!.constraints = [SCNConstraint]()
            }
            rightKnee!.constraints!.append(kneeConstraint)
        }
        */
        
        self.workingNode.addChildNode(self.rootBone)
        
        //showBoneTree(self.rootBone)
        showBoneList()
    }
    
    func readFace() {
        self.faceCount = Int(getUnsignedInt())

        for _ in 0..<self.faceCount {
            let name = getTextBuffer()
            let englishName = getTextBuffer()
            
            let panelNo = getUnsignedByte()
            let type = getUnsignedByte()
            let offsetCount = Int(getInt())

            switch(type) {
            case 0: // group morph
                readGroupMorph(offsetCount)
            case 1: // vertex morph
                readVertexMorph(offsetCount)
            case 2: // bone morph
                readBoneMorph(offsetCount)
            case 3: // UV morph
                readUVMorph(offsetCount, textureNo: 0)
            case 4: // additional UV - 1
                readUVMorph(offsetCount, textureNo: 1)
            case 5: // additional UV - 2
                readUVMorph(offsetCount, textureNo: 2)
            case 6: // additional UV - 3
                readUVMorph(offsetCount, textureNo: 3)
            case 7: // additional UV - 4
                readUVMorph(offsetCount, textureNo: 4)
            case 8: // material morph
                readMaterialMorph(offsetCount)
            default: // unknown type
                break
            }
        }
    }
    
    func readVertexMorph(_ count: Int) {
        for _ in 0..<count {
            let index = getIntOfLength(self.indexSize)
            let x = getFloat()
            let y = getFloat()
            let z = -getFloat()
        }
    }
    
    func readUVMorph(_ count: Int, textureNo: Int) {
        for _ in 0..<count {
            let index = getIntOfLength(self.indexSize)
            let x = getFloat()
            let y = getFloat()
            let z = getFloat()
            let w = getFloat()
        }
    }
    
    func readBoneMorph(_ count: Int) {
        for _ in 0..<count {
            let index = getIntOfLength(self.indexSize)
            let posX = getFloat()
            let posY = getFloat()
            let posZ = -getFloat()
            
            let quatX = getFloat()
            let quatY = getFloat()
            let quatZ = getFloat()
            let quatW = getFloat()
        }
    }
    
    func readMaterialMorph(_ count: Int) {
        for _ in 0..<count {
            let index = getIntOfLength(self.materialIndexSize)
            let addColor = getUnsignedByte()
            
            #if os(iOS) || os(watchOS)
                
                let diffuseColor = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: getFloat())
                let SpecularColor = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: 1.0)
                let shininess = CGFloat(getFloat())
                let ambientColor = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: 1.0)
                //material.emission.contents = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
                let edgeColor = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: getFloat())
                let edgeSize = getFloat()
                let textureColor = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: getFloat())
                let sphereColor = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: getFloat())
                let toonColor = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: getFloat())

                
            #elseif os(OSX)
                
                let diffuseColor = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: CGFloat(getFloat()))
                let specularColor = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: 1.0)
                let shininess = CGFloat(getFloat())
                let ambientColor = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: 1.0)
                //material.emission.contents = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
                let edgeColor = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: CGFloat(getFloat()))

                let edgeSize = getFloat()
                let textureColor = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: CGFloat(getFloat()))

                let sphereColor = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: CGFloat(getFloat()))

                let toonColor = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: CGFloat(getFloat()))

                
            #endif
        }
        
    }
    
    func readGroupMorph(_ count: Int) {
        for _ in 0..<count {
            let morphIndex = getIntOfLength(self.morphIndexSize)
            let rate = getFloat()
        }
    }
    
    
    func readDisplayInfo() {
        let displayCount = Int(getUnsignedInt())
        
        for _ in 0..<displayCount {
            let infoName = getTextBuffer()
            let englishInfoName = getTextBuffer()
            let flag = getUnsignedByte()
            let infoCount = getInt()
            
            for _ in 0..<infoCount {
                let type = getUnsignedByte()
                
                if type == 0 {
                    let boneIndex = getIntOfLength(self.boneIndexSize)
                } else if type == 1 {
                    let morphIndex = getIntOfLength(self.morphIndexSize)
                } else {
                    // unknown type
                }
            }
        }
    }
    
    func createGeometry() {
        //let vertexData = Data(bytes: UnsafePointer<UInt8>(self.vertexArray), count: 4 * 3 * self.vertexCount)
        let vertexData = NSData(bytes: self.vertexArray, length: 4 * 3 * self.vertexCount)
        //let normalData = Data(bytes: UnsafePointer<UInt8>(self.normalArray), count: 4 * 3 * self.vertexCount)
        let normalData = NSData(bytes: self.normalArray, length: 4 * 3 * self.vertexCount)
        //let texcoordData = Data(bytes: UnsafePointer<UInt8>(self.texcoordArray), count: 4 * 2 * self.vertexCount)
        let texcoordData = NSData(bytes: self.texcoordArray, length: 4 * 2 * self.vertexCount)
        //let boneWeightsData = Data(bytes: UnsafePointer<UInt8>(self.boneWeightsArray), count: 4 * 4 * self.vertexCount)
        let boneWeightsData = NSData(bytes: self.boneWeightsArray, length: 4 * 4 * self.vertexCount)
        //let edgeData = NSData(bytes: self.edgeArray, length: 1 * 1 * self.vertexCount)
        
        var boneIndicesData: Data! = nil
        switch(self.boneIndexSize) {
        case 1:
            var array = [UInt8]()
            for data in self.boneIndicesArray {
                array.append(UInt8(data))
            }
            boneIndicesData = Data(bytes: UnsafePointer<UInt8>(array), count: 1 * 4 * self.vertexCount)
        case 2:
            var array = [UInt16]()
            for data in self.boneIndicesArray {
                array.append(UInt16(data))
            }
            boneIndicesData = NSData(bytes: array, length: 2 * 4 * self.vertexCount) as Data!
        case 4:
            var array = [UInt32]()
            for data in self.boneIndicesArray {
                array.append(UInt32(data))
            }
            boneIndicesData = NSData(bytes: array, length: 4 * 4 * self.vertexCount) as Data!
        default: break
            // unknown size
        }
        
        
        self.vertexSource = SCNGeometrySource(data: vertexData as Data, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        self.normalSource = SCNGeometrySource(data: normalData as Data, semantic: SCNGeometrySource.Semantic.normal, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        self.texcoordSource = SCNGeometrySource(data: texcoordData as Data, semantic: SCNGeometrySource.Semantic.texcoord, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        
        let boneIndicesSource = SCNGeometrySource(data: boneIndicesData, semantic: SCNGeometrySource.Semantic.boneIndices, vectorCount: Int(vertexCount), usesFloatComponents: false, componentsPerVector: 4, bytesPerComponent: self.boneIndexSize, dataOffset: 0, dataStride: 4 * self.boneIndexSize)
        let boneWeightsSource = SCNGeometrySource(data: boneWeightsData as Data, semantic: SCNGeometrySource.Semantic.boneWeights, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 4, bytesPerComponent: 4, dataOffset: 0, dataStride: 16)
        
        for index in 0..<self.materialCount {
            let count = materialIndexCountArray[index]
            
            let indexArray = self.separatedIndexArray[index]
            var indexData: Data! = nil
            switch(self.indexSize) {
            case 1:
                var array = [UInt8]()
                for data in indexArray {
                    array.append(UInt8(data))
                }
                indexData = NSData(bytes: array, length: 1 * indexArray.count) as Data!
            case 2:
                var array = [UInt16]()
                for data in indexArray {
                    array.append(UInt16(data))
                }
                indexData = NSData(bytes: array, length: 2 * indexArray.count) as Data!
            case 4:
                var array = [UInt32]()
                for data in indexArray {
                    array.append(UInt32(data))
                }
                indexData = NSData(bytes: array, length: 4 * indexArray.count) as Data!
            default: break
                // unknown size
            }
            
            let primitiveType = self.materialShapeArray[index]
            let element = SCNGeometryElement(data: indexData, primitiveType: primitiveType, primitiveCount: count, bytesPerIndex: self.indexSize)
            print("***** Element ***** \(indexData.count), \(primitiveType), \(count), \(self.indexSize)")

            self.elementArray.append(element)
        }
        
#if !os(watchOS)
        print("****************** create program start ***************************")
        let program = MMDProgram()
        //program.delegate = self.workingNode
        
        /*
        var path = NSBundle(forClass: MMDProgram.self).pathForResource("MMDShader", ofType: "vsh")
        let vertexShader = try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
        program.vertexShader = vertexShader
        
        path = NSBundle(forClass: MMDProgram.self).pathForResource("MMDShader", ofType: "fsh")
        let fragmentShader = try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
        program.fragmentShader = fragmentShader
        
        program.setSemantic(SCNModelViewProjectionTransform, forSymbol: "modelViewProjectionTransform", options: nil)
        program.setSemantic(SCNGeometrySourceSemanticVertex, forSymbol: "aPos", options: nil)
        */
        print("****************** create program end ***************************")
        
        
        
        
        
        /*
        for material in self.materialArray {
        material.program = program
        }
        */
#endif
        
        let geometry = SCNGeometry(sources: [self.vertexSource, self.normalSource, self.texcoordSource], elements: self.elementArray)
        geometry.materials = self.materialArray
        geometry.name = "Geometry"
        
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.name = "Geometry"
        
        let skinner = SCNSkinner(baseGeometry: geometry, bones: self.boneArray, boneInverseBindTransforms: self.boneInverseMatrixArray, boneWeights: boneWeightsSource, boneIndices: boneIndicesSource)
        
        geometryNode.skinner = skinner
        //geometryNode.skinner!.skeleton = self.rootBone
        geometryNode.skinner!.skeleton = self.workingNode
        geometryNode.castsShadow = true
        
        //let program = MMDProgram()
        //geometryNode.geometry!.program = program
        
        self.workingNode.name = "rootNode" // FIXME: set model name or file name
        self.workingNode.addChildNode(geometryNode)
        self.workingNode.addChildNode(self.rootBone)
        
        //showBoneTree(self.rootBone)
        
        // FIXME: use morpher
        /*
        self.workingNode.faceIndexArray = [Int]()
        self.workingNode.faceDataArray = [[Float32]]()
        self.workingNode.faceWeights = [MMDFloat]()
        self.workingNode.vertexArray = self.vertexArray
        for index in self.faceIndexArray {
            self.workingNode.faceIndexArray!.append(index * 3 + 0)
            self.workingNode.faceIndexArray!.append(index * 3 + 1)
            self.workingNode.faceIndexArray!.append(index * 3 + 2)
        }
        for faceNo in 0..<self.faceCount {
            var orgFaceData = self.faceVertexArray[faceNo]
            var newFaceData = [Float32]()
            for i in 0..<self.workingNode.faceIndexArray!.count {
                let faceIndex = self.workingNode.faceIndexArray![i]
                //newFaceData[i] = orgFaceData[faceIndex]
                newFaceData.append(orgFaceData[faceIndex])
            }
            self.workingNode.faceDataArray!.append(newFaceData)
            self.workingNode.faceWeights!.append(MMDFloat())
        }
        
        
        //self.workingNode.normalSource = self.normalSource
        //self.workingNode.texcoordSource = self.texcoordSource
        //self.workingNode.elementArray = self.elementArray
        //self.workingNode.boneIndicesSource = boneIndicesSource
        //self.workingNode.boneWeightsSource = boneWeightsSource
        self.workingNode.boneArray = self.boneArray
        self.workingNode.boneInverseMatrixArray = self.boneInverseMatrixArray
        
        self.workingNode.vertexCount = self.vertexCount
        self.workingNode.vertexArray = self.vertexArray
        self.workingNode.normalArray = self.normalArray
        self.workingNode.texcoordArray = self.texcoordArray
        self.workingNode.boneIndicesArray = self.boneIndicesArray
        self.workingNode.boneWeightsArray = self.boneWeightsArray
        self.workingNode.indexCount = self.indexCount
        self.workingNode.indexArray = self.indexArray
        self.workingNode.materialCount = self.materialCount
        self.workingNode.materialArray = self.materialArray
        self.workingNode.materialIndexCountArray = self.materialIndexCountArray
        self.workingNode.rootBone = self.rootBone
        */
    }
    
    func readPhysicsBody() {
        let bodyCount = Int(getUnsignedInt())
        
        for _ in 0..<bodyCount {
            let name = getTextBuffer()
            let englishName = getTextBuffer()
            let boneIndex = getIntOfLength(self.boneIndexSize)
            
            let groupIndex = Int(getUnsignedByte())
            let groupTarget = Int(getUnsignedShort())
            let shapeType = Int(getUnsignedByte())
            let dx = CGFloat(getFloat())
            let dy = CGFloat(getFloat())
            let dz = CGFloat(getFloat())
            let posX = CGFloat(getFloat())
            let posY = CGFloat(getFloat())
            let posZ = CGFloat(-getFloat())
            let rotX = CGFloat(getFloat())
            let rotY = CGFloat(getFloat())
            let rotZ = CGFloat(-getFloat())
            let weight = CGFloat(getFloat())
            let positionDim = CGFloat(getFloat())
            let rotateDim = CGFloat(getFloat())
            let recoil = CGFloat(getFloat())
            let friction = CGFloat(getFloat())
            let type = Int(getUnsignedByte())
            
            var bodyType: SCNPhysicsBodyType! = nil
            if type == 0 {
                bodyType = SCNPhysicsBodyType.kinematic
            } else if type == 1 {
                bodyType = SCNPhysicsBodyType.dynamic
            } else if type == 2 {
                bodyType = SCNPhysicsBodyType.dynamic
            }
            bodyType = SCNPhysicsBodyType.kinematic // for debug
            
            var shape: SCNGeometry! = nil
            if shapeType == 0 {
                shape = SCNSphere(radius: dx)
            } else if shapeType == 1 {
                shape = SCNBox(width: dx, height: dy, length: dz, chamferRadius: 0.0)
            } else if shapeType == 2 {
                shape = SCNCapsule(capRadius: dx, height: dy)
            } else {
                print("unknown physics body shape")
            }
            
            
            let body = SCNPhysicsBody(type: bodyType, shape: SCNPhysicsShape(geometry: shape, options: nil))
            
            body.isAffectedByGravity = true
            body.mass = weight
            body.friction = friction
            body.rollingFriction = rotateDim
            body.collisionBitMask = groupTarget
            body.restitution = recoil
            body.usesDefaultMomentOfInertia = true
            
            if boneIndex == -1 {
                let bone = self.boneArray[boneIndex]
                bone.physicsBody = body
                print("physicsBody: \(name) -> \(bone.name)")
            }else{
                print("physicsBody: \(name) -> nil")
            }
            
            self.physicsBodyArray.append(body)
        }
    }
    
    func readConstraint() {
        let constraintCount = Int(getUnsignedInt())
        
        for _ in 0..<constraintCount {
            let name = getTextBuffer()
            let englishName = getTextBuffer()
            
            let type = getUnsignedByte()
            
            let bodyANo = getIntOfLength(self.physicsBodyIndexSize)
            let bodyBNo = getIntOfLength(self.physicsBodyIndexSize)
            
            let bodyA = self.physicsBodyArray[bodyANo]
            let bodyB = self.physicsBodyArray[bodyBNo]
            
            print("name: \(name), bodyA: \(bodyANo), bodyB: \(bodyBNo)")
            
            let pos = SCNVector3(getFloat(), getFloat(), -getFloat())
            let rot = SCNVector3(getFloat(), getFloat(), -getFloat())
            
            let minPos = SCNVector3(getFloat(), getFloat(), -getFloat())
            let maxPos = SCNVector3(getFloat(), getFloat(), -getFloat())
            
            let minRot = SCNVector3(getFloat(), getFloat(), -getFloat())
            let maxRot = SCNVector3(getFloat(), getFloat(), -getFloat())

            let spring_pos = SCNVector3(getFloat(), getFloat(), -getFloat())
            let sprint_rot = SCNVector3(getFloat(), getFloat(), -getFloat())
            
            //let constraint = SCNPhysicsBallSocketJoint(bodyA: bodyA, anchorA: pos1, bodyB: bodyB, anchorB: pos2)
        }
    }
    
    func showBoneTree(_ bone: SCNNode, prefix: String = "") {
        print("\(prefix)\(bone.name)")
        let newPrefix = "\(prefix)    "
        for child in bone.childNodes {
            showBoneTree(child, prefix: newPrefix)
        }
    }
    
    func showBoneList() {
        let count = self.boneArray.count
        
        for index in 0..<count {
            let bone = self.boneArray[index]
            print("\(index): \(bone.name)")
        }
    }
}
