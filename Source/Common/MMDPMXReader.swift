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
    #if os(iOS) || os(tvOS) || os(watchOS)
        fileprivate var textureArray: [UIImage]! = nil
    #elseif os(macOS)
        private var textureArray: [NSImage]! = nil
    #endif
    
    // MARK: material data
    fileprivate var materialCount = 0
    fileprivate var materialArray: [SCNMaterial]! = nil
    //fileprivate var materialArray: [MMDMaterial]! = nil
    fileprivate var materialIndexCountArray: [Int]! = nil
    fileprivate var materialShapeArray: [SCNGeometryPrimitiveType]! = nil
    fileprivate var shaderModifiers = [SCNShaderModifierEntryPoint : String]()
    
    // MARK: bone data
    fileprivate var boneCount = 0
    fileprivate var boneArray: [MMDNode]! = nil
    fileprivate var boneInverseMatrixArray: [NSValue]! = nil
    fileprivate var rootBone: MMDNode! = nil
    fileprivate var boneHash: [String:MMDNode]! = nil
    
    // MARK: IK data
    fileprivate var ikCount = 0
    //fileprivate var ikArray: [MMDNode]! = nil
    
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
    fileprivate var physicsBoneArray: [MMDNode]! = nil
    fileprivate var constraintArray: [SCNPhysicsBehavior]! = nil
    
    // MARK: geometry data
    fileprivate var vertexSource: SCNGeometrySource! = nil
    fileprivate var normalSource: SCNGeometrySource! = nil
    fileprivate var texcoordSource: SCNGeometrySource! = nil
    fileprivate var elementArray: [SCNGeometryElement]! = nil
    fileprivate var separatedIndexData: [Data]! = nil
    
    /*
    fileprivate static let shaderModifiers = [
        SCNShaderModifierEntryPoint.fragment:
            "#pragma arguments" +
            "sampler2D texture" +
            "#pragma body" +
            "_output.color.r = _output.color.r * texture" +
            ""
    ]
 */
    
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
        //self.materialArray = [MMDMaterial]()
        self.materialIndexCountArray = [Int]()
        self.materialShapeArray = [SCNGeometryPrimitiveType]()
        
        #if os(iOS) || os(tvOS) || os(watchOS)
            self.textureArray = [UIImage]()
        #elseif os(macOS)
            self.textureArray = [NSImage]()
        #endif
        
        self.boneCount = 0
        self.boneArray = [MMDNode]()
        self.boneHash = [String:MMDNode]()
        self.boneInverseMatrixArray = [NSValue]()
        self.rootBone = MMDNode()
        
        self.ikCount = 0
        self.workingNode.ikArray = [MMDIKConstraint]()
        
        self.physicsBodyCount = 0
        self.physicsBodyArray = [SCNPhysicsBody]()
        self.physicsBoneArray = [MMDNode]()
        self.constraintArray = [SCNPhysicsBehavior]()
        
        self.faceCount = 0
        self.faceIndexArray = [Int]()
        self.faceNameArray = [String]()
        self.faceVertexArray = [[Float32]]()
        
        self.elementArray = [SCNGeometryElement]()
        
        // read contents of file
        self.readPMXHeader()
        if(self.pmxMagic != "PMX ") {
            print("This PMX file is in the wrong format: \(self.pmxMagic)")
            // file is in the wrong format
            return nil
        }
        
        // load shader modifiers
        #if !os(watchOS)
        self.shaderModifiers[.fragment] = try! String(contentsOf: URL(fileURLWithPath: Bundle(for: MMDProgram.self).path(forResource: "MMDFragment", ofType: "shader")!))
        #endif
        
        // read basic data
        self.readVertex()
        self.readIndex()
        self.readTexture()
        self.readMaterial()
        self.readBone()
        //self.readIK()
        self.readFace()
        self.readDisplayInfo()
        
        //showBoneIndexData()
        
        // create geometry for shader
        self.createGeometry()
        self.createFaceMorph()
        
        self.readPhysicsBody()
        self.readConstraint()
        
        if(self.version > 2.0){
            self.readSoftBody()
        }
        
        self.workingNode.categoryBitMask = 0x02 // debug
        
        return self.workingNode
    }
    
    fileprivate func getTextBuffer() -> NSString {
        let strlen = Int(getUnsignedInt())
//        return getString(strlen, encoding: self.encoding)!

        let str = getString(length: strlen, encoding: self.encoding)!
        
        //print("getTextBuffer: \(str)")
        
        return str
    }
    
    /**
     read PMX header data
     */
    fileprivate func readPMXHeader() {
        self.pmxMagic = String(getString(length: 4)!)
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
                _ = getFloat()
                _ = getFloat()
                _ = getFloat()
                _ = getFloat()
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
                _ = getFloat()
                _ = getFloat()
                _ = getFloat()
                
                // FIXME: use SDEF-R0
                _ = getFloat()
                _ = getFloat()
                _ = getFloat()
                
                // FIXME: use SDEF-R1
                _ = getFloat()
                _ = getFloat()
                _ = getFloat()
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
                print("unknown skin weight type: \(weightType)")
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
            let fileName = (self.directoryPath as NSString).appendingPathComponent(String(textureFile)).replacingOccurrences(of: "\\", with: "/")

            print("***** textureName: \(textureFile) => \(fileName) *****")
            
            #if os(iOS) || os(tvOS) || os(watchOS)
                var image = UIImage(contentsOfFile: fileName as String)
                if image == nil {
                    image = UIImage()
                }
            #elseif os(macOS)
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
            //let material = MMDMaterial()
            material.name = getTextBuffer() as String
            
            let englishName = getTextBuffer()
            
            #if os(iOS) || os(tvOS) || os(watchOS)
                
                material.diffuse.contents = UIColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: getCGFloat())
                material.specular.contents = UIColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: 1.0)
                material.shininess = CGFloat(getFloat())
                material.ambient.contents = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
                material.emission.contents = NSColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: 1.0)

                let bitFlag = getUnsignedByte()
                let edgeColor = UIColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: getCGFloat())

            #elseif os(macOS)

                material.diffuse.contents = NSColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: getCGFloat())
                material.specular.contents = NSColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: 1.0)
                material.shininess = getCGFloat()
                material.ambient.contents = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
                material.emission.contents = NSColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: 1.0)
                
                let bitFlag = getUnsignedByte()
                let edgeColor = NSColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: getCGFloat())
                
            #endif
            
            material.setValue(edgeColor, forKey: "edgeColor")
            

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
            
            if textureNo < self.textureArray.count {
                let texture = self.textureArray[textureNo]
                material.multiply.contents = texture
                material.multiply.wrapS = .repeat
                material.multiply.wrapT = .repeat
                material.setValue(1.0, forKey: "useTexture")
            } else {
                material.setValue(0.0, forKey: "useTexture")
            }
            
            if toonFlag == 0 {
                // use own texture
                let toonTextureNo = getIntOfLength(self.textureIndexSize)
                if toonTextureNo < self.textureArray.count {
                    let toonTexture = self.textureArray[toonTextureNo]
                    material.transparent.contents = toonTexture
                    material.setValue(1.0, forKey: "useToon")
                } else {
                    material.setValue(0.0, forKey: "useToon")
                }
            } else if toonFlag == 1 {
                // use shared texture
                let toonTextureNo = Int(getUnsignedByte())
                // TODO: load the shared toon textures
                // let toonTexture = self.toonTextureArray[toonTextureNo]
                // material.multiply.contents = toonTextureNo
                // material.setValue(true, forKey: "useToon")
                material.setValue(0.0, forKey: "useToon")
            } else {
                // unknown flag
                material.setValue(0.0, forKey: "useToon")
            }
            
            if noCulling {
                material.isDoubleSided = true
            } else {
                material.isDoubleSided = false
            }
            
            if sphereTextureNo >= 255 {
                material.setValue(0.0, forKey: "useSphereMap")
                material.setValue(0.0, forKey: "spadd")
                material.setValue(0.0, forKey: "useSubtexture")
            } else {
                let sphereTexture = self.textureArray[sphereTextureNo]
                print("sphereMode: \(sphereMode)")
                if sphereMode == 0 {
                    // disable
                    material.setValue(0.0, forKey: "useSphereMap")
                    material.setValue(0.0, forKey: "spadd")
                    material.setValue(0.0, forKey: "useSubtexture")
                }else if sphereMode == 1 {
                    // multiplicative
                    material.setValue(1.0, forKey: "useSphereMap")
                    material.setValue(0.0, forKey: "spadd")
                    material.setValue(0.0, forKey: "useSubtexture")
                    material.reflective.contents = sphereTexture
                }else if sphereMode == 2 {
                    // additive
                    material.setValue(1.0, forKey: "useSphereMap")
                    material.setValue(1.0, forKey: "spadd")
                    material.setValue(0.0, forKey: "useSubtexture")
                    material.reflective.contents = sphereTexture
                }else if sphereMode == 3 {
                    // subtexture
                    material.setValue(1.0, forKey: "useSpehreMap")
                    material.setValue(1.0, forKey: "spadd")
                    material.setValue(0.0, forKey: "useSubtexture")
                    material.reflective.contents = sphereTexture
                }else{
                    // unknown
                    material.setValue(0.0, forKey: "useSphereMap")
                    material.setValue(0.0, forKey: "spadd")
                    material.setValue(0.0, forKey: "useSubtexture")
                }
            }
            
            // FIXME: use floorShadow, shadowMap property
            // FIXME: use drawEdge property
            // FIXME: use vertexColor

            var shape: SCNGeometryPrimitiveType = .triangles
            if drawPoint {
                shape = .point
                print("drawPoint")
            } else if drawLine {
                shape = .line
                print("drawLine")
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
            
            material.shaderModifiers = self.shaderModifiers
            
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
        //var ikTargetNoArray = [Int]()
        //var ikLinkNoArray = [[Int]]()
        
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
            
            let maxLen = boneNode.name!.characters.count
            if maxLen >= 3 {
                let kneeName = (boneNode.name! as NSString).substring(to: 3)
                if kneeName == "右ひざ" || kneeName == "左ひざ" {
                    boneNode.isKnee = true
                }
            }

            
            #if os(iOS) || os(tvOS) || os(watchOS)
                let x = getFloat()
                let y = getFloat()
                let z = -getFloat()
            #elseif os(macOS)
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
                _ = getFloat()
                _ = getFloat()
                _ = getFloat()
            }
            
            print("\(index): \(String(describing: boneNode.name))")
            if hasRotationValue || hasTranslationValue {
                let boneIndex = getIntOfLength(self.boneIndexSize)
                let rate = getFloat()
                
                let bone = self.boneArray[boneIndex]
                print("   rotation/translation: [\(boneIndex)] \(String(describing: bone.name)) \(rate)")
                
                if hasRotationValue {
                    boneNode.rotateEffector = bone
                    boneNode.rotateEffectRate = rate
                }
                if hasTranslationValue {
                    boneNode.translateEffector = bone
                    boneNode.translateEffectRate = rate
                }
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
                let ik = MMDIKConstraint()

                let targetBoneNo = getIntOfLength(self.boneIndexSize)
                let targetBone = self.boneArray[targetBoneNo]
                //ikTargetNoArray.append(targetBoneNo)
                
                let iteration = getInt()
                let weight = getFloat()
                let numLink = getInt()
                
                ik.ikBone = boneNode
                ik.targetBone = targetBone
                ik.iteration = Int(iteration)
                ik.weight = Float(Double(weight) * 0.25 * Double.pi)
                ik.boneArray = [MMDNode]()
                
                print("targetBoneNo: \(targetBoneNo) \(String(describing: targetBone.name)), ikBone: \(String(describing: ik.ikBone.name))")
                
                var linkBoneNoArray = [Int]()
                for _ in 0..<numLink {
                    let linkNo = Int(getUnsignedShort())
                    let bone = self.boneArray[linkNo]
                    
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
                    
                    ik.boneArray.append(bone)
                    //bone.ikEffector = boneNode
                }
                
                self.workingNode.ikArray!.append(ik)
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
            
            self.boneInverseMatrixArray.append(NSValue(scnMatrix4: matrix))
        }
        
        self.boneArray.append(self.rootBone)
        self.boneInverseMatrixArray.append(NSValue(scnMatrix4: SCNMatrix4Identity))
        
        /*
        self.workingNode.position = SCNVector3Make(0, 0, 0)
        self.boneArray.append(self.workingNode)
        self.boneInverseMatrixArray.append(NSValue(SCNMatrix4: SCNMatrix4Identity))
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
        
        // update IK info
        /*
        for index in 0..<self.workingNode.ikArray!.count {
            let targetNo = ikTargetNoArray[index]

            let ik = self.workingNode.ikArray![index]
            ik.targetBone = self.boneArray[targetNo]
            
            print("ik: \(ik.ikBone.name) => \(ik.targetBone.name)")
            let linkBoneNoArray = ikLinkNoArray[index]
            for linkNo in linkBoneNoArray {
                let bone = self.boneArray[linkNo]
                print("  linkNo: \(linkNo), \(bone.name!)")
                ik.boneArray.append(bone)
            }
            
            //let chainRootNode = self.boneArray[ linkBoneNoArray[linkCount-1] ]
            //let constraint = SCNIKConstraint.inverseKinematicsConstraint(chainRootNode: chainRootNode)
            //if ik.targetBone.constraints == nil {
            //    ik.targetBone.constraints = [SCNConstraint]()
            //}
            //ik.targetBone.constraints!.append(constraint)
        }
 */
        
        self.workingNode.addChildNode(self.rootBone)
        
        //showBoneTree(self.rootBone)
        //showBoneList()
        
        //for ik in self.workingNode.ikArray! {
        //    ik.printInfo()
        //}
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
                self.faceNameArray.append(name as String)
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
            case 9: // flip morph
                readFlipMorph(offsetCount)
            case 10: // impulse morph
                readImpulseMorph(offsetCount)
            default: // unknown type
                break
            }
        }
    }
    
    func readVertexMorph(_ count: Int) {
        var faceVertex = [Float32](repeating: 0, count: self.vertexArray.count)

        for _ in 0..<count {
            let index = getIntOfLength(self.indexSize)
            let vertexIndex = index * 3
            
            let x = getFloat()
            let y = getFloat()
            let z = -getFloat()
            
            faceVertex[vertexIndex + 0] = x
            faceVertex[vertexIndex + 1] = y
            faceVertex[vertexIndex + 2] = z
        }
        
        self.faceVertexArray.append(faceVertex)
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
            let index = getIntOfLength(self.boneIndexSize)
            print("bone morph: index \(index)")
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
            
            #if os(iOS) || os(tvOS) || os(watchOS)
                
                let diffuseColor = UIColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: getCGFloat())
                let SpecularColor = UIColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: 1.0)
                let shininess = getCGFloat()
                let ambientColor = UIColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: 1.0)
                //material.emission.contents = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
                let edgeColor = UIColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: getCGFloat())
                let edgeSize = getCGFloat()
                let textureColor = UIColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: getCGFloat())
                let sphereColor = UIColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: getCGFloat())
                let toonColor = UIColor(red: getCGFloat(), green: getCGFloat(), blue: getCGFloat(), alpha: getCGFloat())

                
            #elseif os(macOS)
                
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

    func readFlipMorph(_ count: Int) {
        for _ in 0..<count {
            let morphIndex = getIntOfLength(self.morphIndexSize)
            let rate = getFloat()
        }
    }

    func readImpulseMorph(_ count: Int) {
        for _ in 0..<count {
            let morphIndex = getIntOfLength(self.morphIndexSize)
            let isLocal = Int(getUnsignedByte())
         
            let vx = getFloat()
            let vy = getFloat()
            let vz = -getFloat()

            let torqueX = getFloat()
            let torqueY = getFloat()
            let torqueZ = getFloat()
        }
    }
    
    func createFaceMorph() {
        let morpher = SCNMorpher()
        morpher.calculationMode = .additive
        
        for index in 0..<self.faceVertexArray.count {
            let faceVertexData = NSData(bytes: self.faceVertexArray[index], length: 4 * 3 * self.vertexCount)
            let faceVertexSource = SCNGeometrySource(data: faceVertexData as Data, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: Int(self.vertexCount), usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
            
            //let faceGeometry = SCNGeometry(sources: [faceVertexSource], elements: [])
            let faceGeometry = SCNGeometry(sources: [faceVertexSource, self.normalSource], elements: [])
            faceGeometry.name = self.faceNameArray[index]
            
            morpher.targets.append(faceGeometry)
        }
        let geometryNode = self.workingNode.childNode(withName: "Geometry", recursively: true)
        geometryNode!.morpher = morpher
        
        self.workingNode.geometryMorpher = morpher
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
        let vertexData = NSData(bytes: self.vertexArray, length: 4 * 3 * self.vertexCount)
        let normalData = NSData(bytes: self.normalArray, length: 4 * 3 * self.vertexCount)
        let texcoordData = NSData(bytes: self.texcoordArray, length: 4 * 2 * self.vertexCount)
        let boneWeightsData = NSData(bytes: self.boneWeightsArray, length: 4 * 4 * self.vertexCount)
        
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
            
            // FIXME: use Point/Line in the A-A-A pattern or the A-B-A pattern
            
            let primitiveType = self.materialShapeArray[index]
            let element = SCNGeometryElement(data: indexData, primitiveType: primitiveType, primitiveCount: count, bytesPerIndex: self.indexSize)
            print("***** Element ***** \(indexData.count), \(primitiveType), \(count), \(self.indexSize)")

            self.elementArray.append(element)
        }
        
#if !os(watchOS)
        //print("****************** create program start ***************************")
        //let program = MMDProgram()
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
        //print("****************** create program end ***************************")
        //for material in self.materialArray {
        //    material.program = program
        //}


    #endif
        
        let geometry = SCNGeometry(sources: [self.vertexSource, self.normalSource, self.texcoordSource], elements: self.elementArray)
        geometry.materials = self.materialArray
        geometry.name = "Geometry"
        
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.name = "Geometry"
        
        let skinner = SCNSkinner(baseGeometry: geometry, bones: self.boneArray, boneInverseBindTransforms: self.boneInverseMatrixArray, boneWeights: boneWeightsSource, boneIndices: boneIndicesSource)
        
        geometryNode.skinner = skinner
        geometryNode.skinner!.skeleton = self.rootBone
        geometryNode.castsShadow = true
        
        self.workingNode.name = "rootNode" // FIXME: set model name or file name
        self.workingNode.castsShadow = true
        self.workingNode.addChildNode(geometryNode)
        
        //showBoneTree(self.rootBone)
        
        // FIXME: use morpher
        self.workingNode.vertexArray = self.vertexArray

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
        */
        
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
        // FIXME: [Int]! to [UInt16]!
        //self.workingNode.boneIndicesArray = self.boneIndicesArray
        self.workingNode.boneWeightsArray = self.boneWeightsArray
        self.workingNode.indexCount = self.indexCount
        // FIXME: [Int]! to [UInt16]!
        //self.workingNode.indexArray = self.indexArray
        self.workingNode.materialCount = self.materialCount
        self.workingNode.materialArray = self.materialArray
        self.workingNode.materialIndexCountArray = self.materialIndexCountArray
        self.workingNode.rootBone = self.rootBone
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
            let posX = OSFloat(getFloat())
            let posY = OSFloat(getFloat())
            let posZ = OSFloat(-getFloat())
            let rotX = OSFloat(-getFloat())
            let rotY = OSFloat(-getFloat())
            let rotZ = OSFloat(getFloat())
            let weight = CGFloat(getFloat())
            let positionDim = CGFloat(getFloat())
            let rotateDim = CGFloat(getFloat())
            let recoil = CGFloat(getFloat())
            let friction = CGFloat(getFloat())
            let type = Int(getUnsignedByte())
            
            print("")
            print("physicsBody: \(name)")
            var bodyType: SCNPhysicsBodyType! = nil
            if type == 0 {
                print("type 0: kinematic")
                bodyType = SCNPhysicsBodyType.kinematic
            } else if type == 1 {
                print("type 1: dynamic")
                bodyType = SCNPhysicsBodyType.dynamic
            } else if type == 2 {
                print("type 2: dynamic")
                bodyType = SCNPhysicsBodyType.dynamic
            }
            bodyType = SCNPhysicsBodyType.kinematic // for debug
            
            var shape: SCNGeometry! = nil
            if shapeType == 0 {
                print("shape: Sphere radius: \(dx)")
                shape = SCNSphere(radius: dx)
            } else if shapeType == 1 {
                print("shape: Box (\(dx), \(dy), \(dz))")
                shape = SCNBox(width: dx, height: dy, length: dz, chamferRadius: 0.0)
            } else if shapeType == 2 {
                print("shape: Capsule (\(dx), \(dy)")
                shape = SCNCapsule(capRadius: dx, height: dy)
            } else {
                print("unknown physics body shape")
            }
            print("pos: \(posX), \(posY), \(posZ)")
            print("rot: \(rotX), \(rotY), \(rotZ)")

            var _bone: MMDNode? = nil
            if boneIndex != -1 {
                _bone = self.boneArray[boneIndex]
            }
            
            var bone: MMDNode
            if _bone != nil {
                bone = _bone!
            } else {
                bone = self.boneArray[0]
            }
            
            //var worldTransform = SCNMatrix4MakeRotation(rotY, 0, 1, 0)
            //worldTransform = SCNMatrix4Rotate(worldTransform, rotX, 1, 0, 0)
            //worldTransform = SCNMatrix4Rotate(worldTransform, rotZ, 0, 0, 1)
            //worldTransform = SCNMatrix4Translate(worldTransform, posX, posY, posZ)
            
            //var worldTransform = SCNMatrix4MakeRotation(rotZ, 0, 0, 1)
            //worldTransform = SCNMatrix4Rotate(worldTransform, rotX, 1, 0, 0)
            //worldTransform = SCNMatrix4Rotate(worldTransform, rotY, 0, 1, 0)
            //worldTransform = SCNMatrix4Translate(worldTransform, posX, posY, posZ)
            
            var worldTransform = SCNMatrix4MakeTranslation(posX, posY, posZ)
            worldTransform = SCNMatrix4Rotate(worldTransform, rotY, 0, 1, 0)
            worldTransform = SCNMatrix4Rotate(worldTransform, rotX, 1, 0, 0)
            worldTransform = SCNMatrix4Rotate(worldTransform, rotZ, 0, 0, 1)
            
            let invBoneTransform = SCNMatrix4Invert(bone.worldTransform)
            let physicsTransform = SCNMatrix4Mult(worldTransform, invBoneTransform)
            let transformValue = NSValue(scnMatrix4: physicsTransform)
            print("physicsTransform.m41-43: \(physicsTransform.m41), \(physicsTransform.m42), \(physicsTransform.m43)")

            let physicsShape = SCNPhysicsShape(geometry: shape, options: nil)
            var transformedShape = SCNPhysicsShape(shapes: [physicsShape], transforms: [transformValue])
            //var transformedShape = physicsShape
            
            if let currentBody = bone.physicsBody {
                let identity = NSValue(scnMatrix4: SCNMatrix4Identity)
                transformedShape = SCNPhysicsShape(shapes: [currentBody.physicsShape!, transformedShape], transforms: [identity, identity])
            }
            
            let body = SCNPhysicsBody(type: bodyType, shape: transformedShape)
            
            body.isAffectedByGravity = true
            body.mass = weight
            body.friction = friction
            body.rollingFriction = friction
            body.damping = positionDim
            body.angularDamping = rotateDim
            body.categoryBitMask = (1 << groupIndex)
            body.collisionBitMask = groupTarget
            body.restitution = recoil
            body.usesDefaultMomentOfInertia = true
            body.allowsResting = true
            body.charge = 0
            //body.angularVelocityFactor = SCNVector3(x: 0.00001, y: 0.00001, z: 0.00001)
            //body.velocityFactor = SCNVector3(x: 0.00001, y: 0.00001, z: 0.00001)
            
            print("groupIndex: \(groupIndex)")
            print("groupTarget: \(groupTarget)")
            
            if boneIndex != -1 {
                bone.physicsBody = body
                print("physicsBody: \(name) -> \(String(describing: bone.name))")
            }else{
                print("physicsBody: \(name) -> nil")
            }
            
            //self.physicsBodyArray.append(body)
            self.physicsBoneArray.append(bone)
        }
        
        for bone in self.physicsBoneArray {
            self.physicsBodyArray.append(bone.physicsBody!)
        }
    }
    
    func readConstraint() {
        let constraintCount = Int(getUnsignedInt())
        
        self.workingNode.joints = [SCNPhysicsBehavior]()
        
        for index in 0..<constraintCount {
            print("")
            print("=== Constraint Index: \(index) ===")
            let name = getTextBuffer()
            let englishName = getTextBuffer()
            
            let type = getUnsignedByte()
            print("\(name) constraint type: \(type)")
            // 0: btGeneric6DofSpringConstraint
            // 1: btGeneric6DofConstraint
            // 2: btPoint2PointConstraint => SCNPhysicsBallSocketJoint
            // 3: btConeTwistConstraint
            // 4: ?
            // 5: btSliderConstraint => SCNPhysicsSliderJoint
            // 6: btHingeConstraint => SCNPhysicsHingeJoint
            
            
            let bodyANo = getIntOfLength(self.physicsBodyIndexSize)
            let bodyBNo = getIntOfLength(self.physicsBodyIndexSize)
            
            let bodyA = self.physicsBodyArray[bodyANo]
            let bodyB = self.physicsBodyArray[bodyBNo]
            
            print("name: \(name), bodyA: \(bodyANo), bodyB: \(bodyBNo)")
            
            let pos = SCNVector3(getFloat(), getFloat(), -getFloat())
            let rot = SCNVector3(getFloat(), getFloat(), -getFloat())
            print("pos: \(pos.x), \(pos.y), \(pos.z)")
            print("rot: \(rot.x), \(rot.y), \(rot.z)")
            
            let minPos = SCNVector3(getFloat(), getFloat(), -getFloat())
            let maxPos = SCNVector3(getFloat(), getFloat(), -getFloat())
            
            let minRot = SCNVector3(getFloat(), getFloat(), -getFloat())
            let maxRot = SCNVector3(getFloat(), getFloat(), -getFloat())

            let springPos = SCNVector3(getFloat(), getFloat(), -getFloat())
            let springRot = SCNVector3(getFloat(), getFloat(), -getFloat())

            let boneA = self.physicsBoneArray[bodyANo]
            let boneB = self.physicsBoneArray[bodyBNo]
            
            let anchorA = SCNVector3(
                x: pos.x - boneA.worldTransform.m41,
                y: pos.y - boneA.worldTransform.m42,
                z: pos.z - boneA.worldTransform.m43
            )
            let anchorB = SCNVector3(
                x: pos.x - boneB.worldTransform.m41,
                y: pos.y - boneB.worldTransform.m42,
                z: pos.z - boneB.worldTransform.m43
            )
            
            print("boneA: \(String(describing: boneA.name)), boneB: \(String(describing: boneB.name))")
            print("anchorA: \(anchorA.x), \(anchorA.y), \(anchorA.z)")
            print("anchorB: \(anchorB.x), \(anchorB.y), \(anchorB.z)")
            assert(bodyA == boneA.physicsBody, "bodyA physicsBody unmatch")
            assert(bodyB == boneB.physicsBody, "bodyB physicsBody unmatch")

            if boneA == boneB {
                print("boneA == boneB. skip")
                continue
            }
            
            let constraint = SCNPhysicsBallSocketJoint(bodyA: bodyA, anchorA: anchorA, bodyB: bodyB, anchorB: anchorB)
    #if false
            let axis = SCNVector3(0, 1, 0)
            let anchor = SCNVector3(0, 0, 0)
            let constraint = SCNPhysicsSliderJoint.init(bodyA: bodyA, axisA: axis, anchorA: anchorA, bodyB: bodyB, axisB: axis, anchorB: anchorB)
            constraint.minimumLinearLimit = 0.00
            constraint.maximumLinearLimit = 0.00
            constraint.minimumAngularLimit = 0.00
            constraint.maximumAngularLimit = 0.00
            constraint.motorMaximumForce = 0.0000
            constraint.motorMaximumTorque = 0.0000
            constraint.motorTargetLinearVelocity = 0
            constraint.motorTargetAngularVelocity = 0
    #endif
            //self.constraintArray.append(constraint)
            self.workingNode.joints!.append(constraint)
        }
    }
    
    func readSoftBody() {
        let softBodyCount = Int(getUnsignedInt())
        
        print("softBodyCount: \(softBodyCount)")

        for _ in 0..<softBodyCount {
            let name = getTextBuffer()
            let englishName = getTextBuffer()
            
            print("    softBody: \(name)")
            
            let shape = Int(getUnsignedByte())
            if shape == 0 {
                // TriMesh
            } else if shape == 1 {
                // Rope
            } else {
                // unknown shape
            }
            
            let index = getIntOfLength(self.materialIndexSize)
            let groupIndex = Int(getUnsignedByte())
            let groupTarget = Int(getUnsignedShort())

            let flags = Int(getUnsignedByte())
            if flags & 0x01 != 0 {
                // create B-Link
            }
            if flags & 0x02 != 0 {
                // create cluster
            }
            if flags & 0x04 != 0 {
                // mix links
            }

            /*
             4  : int	| B-Link 作成距離
             4  : int	| クラスタ数
             
             4  : float	| 総質量
             4  : float	| 衝突マージン
             
             4  : int	| AeroModel - 0:V_Point, 1:V_TwoSided, 2:V_OneSided, 3:F_TwoSided, 4:F_OneSided
             
             <config>
             4  : float	| VCF
             4  : float	| DP
             4  : float	| DG
             4  : float	| LF
             4  : float	| PR
             4  : float	| VC
             4  : float	| DF
             4  : float	| MT
             4  : float	| CHR
             4  : float	| KHR
             4  : float	| SHR
             4  : float	| AHR
             
             <cluster>
             4  : float	| SRHR_CL
             4  : float	| SKHR_CL
             4  : float	| SSHR_CL
             4  : float	| SR_SPLT_CL
             4  : float	| SK_SPLT_CL
             4  : float	| SS_SPLT_CL
             
             <iteration>
             4  : int	| V_IT
             4  : int	| P_IT
             4  : int	| D_IT
             4  : int	| C_IT
             
             <material>
             4  : float	| LST
             4  : float	| AST
             4  : float	| VST
             
             4  : int	| アンカー剛体数
             <アンカー剛体>
             n  : 剛体Indexサイズ  | 関連剛体Index
             n  : 頂点Indexサイズ  | 関連頂点Index
             1  : byte	| Near モード  0:OFF 1:ON
             </アンカー剛体>
             * アンカー剛体数
             
             4  : int	| Pin頂点数
             <Pin頂点>
             n  : 頂点Indexサイズ  | 関連頂点Index
             </Pin頂点>
             * Pin頂点数
             */
        }
    }
 
    func showBoneTree(_ bone: SCNNode, prefix: String = "") {
        print("\(prefix)\(String(describing: bone.name))")
        let newPrefix = "\(prefix)    "
        for child in bone.childNodes {
            showBoneTree(child, prefix: newPrefix)
        }
    }
    
    func showBoneList() {
        let count = self.boneArray.count
        
        for index in 0..<count {
            let bone = self.boneArray[index]
            print("\(index): \(String(describing: bone.name))")
        }
    }
    
    func showBoneIndexData() {
        let numIndices = self.boneIndicesArray.count
        
        for index in 0..<numIndices {
            let i = index % 4
            if i == 0 {
                print("======")
            }
            let boneIndex = self.boneIndicesArray[index]
            let boneWeight = self.boneWeightsArray[index]
            let bone = self.boneArray[boneIndex]
            
            print("\(i): \(boneIndex) (\(String(describing: bone.name))): \(boneWeight)")
        }
    }
}
