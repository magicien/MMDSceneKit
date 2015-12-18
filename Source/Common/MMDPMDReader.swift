//
//  MMDPMDReader.swift
//  MMDSceneKit
//
//  Created by Yuki OHNO on 12/18/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

class MMDPMDReader: MMDReader {
    private var workingNode: MMDNode! = nil
    
    // MARK: PMD header data
    private var pmdMagic: String! = ""
    private var version: Float = 0.0
    private var modelName: String! = ""
    private var comment: String! = ""
    
    // MARK: vertex data
    private var vertexCount = 0
    private var vertexArray: [Float32]! = nil
    private var normalArray: [Float32]! = nil
    private var texcoordArray: [Float32]! = nil
    private var boneIndicesArray: [UInt16]! = nil
    private var boneWeightsArray: [Float32]! = nil
    
    // MARK: index data
    private var indexCount = 0
    private var indexArray: [UInt16]! = nil
    
    // MARK: material data
    private var materialCount = 0
    private var materialArray: [SCNMaterial]! = nil
    private var materialIndexCountArray: [Int]! = nil
    
    // MARK: bone data
    private var boneCount = 0
    private var boneArray: [MMDNode]! = nil
    private var boneInverseMatrixArray: [NSValue]! = nil
    private var rootBone: MMDNode! = nil
    private var boneHash: [String:MMDNode]! = nil
    
    // MARK: IK data
    private var ikCount = 0
    private var ikArray: [MMDNode]! = nil
    
    // MARK: face data
    private var faceCount = 0
    private var faceIndexArray: [Int]! = nil
    private var faceNameArray: [String]! = nil
    private var faceVertexArray: [[Float32]]! = nil
    
    // MARK: display info data
    private var faceDisplayCount = 0
    private var boneDisplayNameCount = 0
    private var boneDisplayCount = 0
    
    // MARK: physics body data
    private var physicsBodyCount = 0
    private var physicsBodyArray: [SCNPhysicsBody]! = nil
    
    // MARK: geometry data
    private var vertexSource: SCNGeometrySource! = nil
    private var normalSource: SCNGeometrySource! = nil
    private var texcoordSource: SCNGeometrySource! = nil
    private var elementArray: [SCNGeometryElement]! = nil
    
    /**
    */
    static func getNode(data: NSData, directoryPath: String! = "") -> MMDNode? {
        let reader = MMDPMDReader(data: data, directoryPath: directoryPath)
        let node = reader.loadPMDFile()
        
        return node
    }
    
    // MARK: - Loading PMD File
    private func loadPMDFile() -> MMDNode? {
        // initialize working variables
        self.workingNode = MMDNode()
        
        self.pmdMagic = ""
        self.version = 0.0
        self.modelName = ""
        self.comment = ""
        
        self.vertexCount = 0
        self.vertexArray = [Float32]()
        self.normalArray = [Float32]()
        self.texcoordArray = [Float32]()
        self.boneIndicesArray = [UInt16]()
        self.boneWeightsArray = [Float32]()
        
        self.indexCount = 0
        self.indexArray = [UInt16]()
        
        self.materialCount = 0
        self.materialArray = [SCNMaterial]()
        self.materialIndexCountArray = [Int]()
        
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
        self.readPMDHeader()
        if(self.pmdMagic != "Pmd") {
            print("file is in the wrong format")
            // file is in the wrong format
            return nil
        }
        
        // read basic data
        self.readVertex()
        self.readIndex()
        self.readMaterial()
        self.readBone()
        self.readIK()
        self.readFace()
        self.readDisplayInfo()
        
        // create geometry for shader
        self.createGeometry()
        self.createFaceMorph()
        
        // read additional data
        
        if (self.pos >= self.length) {
            return self.workingNode
        }
        
        self.readEnglishInfo()
        
        if (self.pos >= self.length) {
            return self.workingNode
        }
        
        self.readToonTexture()
        
        if (self.pos >= self.length) {
            return self.workingNode
        }
        
        self.readPhysicsBody()
        self.readConstraint()
        
        return self.workingNode
    }
    
    /**
     read PMD header data
     */
    private func readPMDHeader() {
        self.pmdMagic = String(getString(3)!)
        print("pmdMagic: \(pmdMagic)")
        self.version = Float(getFloat())
        self.modelName = String(getString(20))
        self.comment = String(getString(256))
    }
    
    /**
     read PMD vertex data
     */
    private func readVertex() {
        // read vertex
        self.vertexCount = Int(getUnsignedInt())
        
        var edgeArray = [UInt8]()
        
        // z value has to be changed negative because SceneKit has right-handed system and MMD has left-handed system
        for _ in 0..<self.vertexCount {
            self.vertexArray.append(getFloat())
            self.vertexArray.append(getFloat())
            self.vertexArray.append(-getFloat())
            
            self.normalArray.append(getFloat())
            self.normalArray.append(getFloat())
            self.normalArray.append(-getFloat())
            
            self.texcoordArray.append(getFloat())
            self.texcoordArray.append(getFloat())
            
            let boneNo1 = getUnsignedShort()
            let boneNo2 = getUnsignedShort()
            
            let weightByte = getUnsignedByte()
            let weight1 = Float32(weightByte) / 100.0
            let weight2 = 1.0 - weight1
            
            // the first weight must not be 0 in SceneKit...
            if weight1 == 0.0 {
                self.boneIndicesArray.append(boneNo2)
                self.boneIndicesArray.append(boneNo1)
                
                self.boneWeightsArray.append(weight2)
                self.boneWeightsArray.append(weight1)
            } else {
                self.boneIndicesArray.append(boneNo1)
                self.boneIndicesArray.append(boneNo2)
                
                self.boneWeightsArray.append(weight1)
                self.boneWeightsArray.append(weight2)
            }
            
            // FIXME: use edge data for rendering
            edgeArray.append(getUnsignedByte())
        }
    }
    
    private func readIndex() {
        self.indexCount = Int(getUnsignedInt())
        
        for _ in 0..<(self.indexCount/3) {
            let index1 = getUnsignedShort()
            let index2 = getUnsignedShort()
            let index3 = getUnsignedShort()
            
            self.indexArray.append(index1)
            self.indexArray.append(index3)
            self.indexArray.append(index2)
        }
    }
    
    private func readMaterial() {
        self.materialCount = Int(getUnsignedInt())
        
        for _ in 0..<self.materialCount {
            let material = SCNMaterial()
            
            #if os(iOS)
                
                material.diffuse.contents = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: getFloat())
                material.shininess = CGFloat(getFloat())
                material.specular.contents = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: 1.0)
                material.ambient.contents = UIColor(colorLiteralRed: getFloat(), green: getFloat(), blue: getFloat(), alpha: 1.0)
                material.emission.contents = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
                
            #elseif os(OSX)
                
                material.diffuse.contents = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: CGFloat(getFloat()))
                material.shininess = CGFloat(getFloat())
                material.specular.contents = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: 1.0)
                material.ambient.contents = NSColor(red: CGFloat(getFloat()), green: CGFloat(getFloat()), blue: CGFloat(getFloat()), alpha: 1.0)
                material.emission.contents = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
                
            #endif
            
            let toonIndex = getUnsignedByte()
            let edge = getUnsignedByte()
            let indexCount = Int(getUnsignedInt())
            let textureFile = getString(20)
            
            print("textureFileName: \(textureFile)")
            if textureFile != "" {
                let fileName = (self.directoryPath as NSString).stringByAppendingPathComponent(String(textureFile!))
                
                print("setTexture: \(fileName)")
                
                #if os(iOS)
                    material.diffuse.contents = UIImage(contentsOfFile: fileName)
                #elseif os(OSX)
                    material.diffuse.contents = NSImage(contentsOfFile: fileName)
                #endif
            }
            material.doubleSided = true
            
            self.materialIndexCountArray.append(indexCount)
            self.materialArray.append(material)
        }
        
    }
    
    private func readBone() {
        self.boneCount = Int(getUnsignedShort())
        
        var parentNoArray = [Int]()
        //var boneInverseMatrixData = [NSValue]()
        var bonePositionArray = [SCNVector3]()
        
        self.rootBone.position = SCNVector3Make(0, 0, 0)
        self.rootBone.name = "rootBone"
        
        for index in 0..<self.boneCount {
            let boneNode = MMDNode()
            boneNode.name = String(getString(20)!)
            
            let parentNo = Int(getUnsignedShort())
            parentNoArray.append(parentNo)
            
            let childNo = getUnsignedShort()
            let type = getUnsignedByte()
            let ikTarget = getUnsignedShort()
            
            #if os(iOS)
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
            self.boneArray.append(boneNode)
            self.boneHash[boneNode.name!] = boneNode
        }
        
        // set parent node
        for index in 0..<self.boneCount {
            let bone = boneArray[index]
            let parentNo = parentNoArray[index]
            let bonePos = bonePositionArray[index]
            
            if (parentNo != 0xFFFF) {
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
            
            self.boneInverseMatrixArray.append(NSValue.init(SCNMatrix4: matrix))
        }
        
        self.boneArray.append(self.rootBone)
        self.boneInverseMatrixArray.append(NSValue.init(SCNMatrix4: SCNMatrix4Identity))
        
        self.workingNode.addChildNode(self.rootBone)
    }
    
    private func readIK() {
        self.ikCount = Int(getUnsignedShort())
        
        for _ in 0..<self.ikCount {
            let targetBoneNo = Int(getUnsignedShort())
            let effectBoneNo = Int(getUnsignedShort())
            let numLink = getUnsignedByte()
            let iteration = getUnsignedShort()
            let weight = getUnsignedInt()
            
            print("targetBoneNo: \(targetBoneNo), effectBoneNo: \(effectBoneNo)")
            for _ in 0..<numLink-1 {
                let linkNo = Int(getUnsignedShort())
                print("linkNo: \(linkNo), \(boneArray[linkNo])")
            }
            
            let rootLinkNo = Int(getUnsignedShort())
            print("rootLinkNo: \(rootLinkNo)")
            
            /*
            let chainRootNode = boneArray[rootLinkNo]
            let constraint = SCNIKConstraint.init(chainRootNode: chainRootNode)
            
            let effectNode = boneArray[effectBoneNo]
            if effectNode.constraints == nil {
            effectNode.constraints = [SCNConstraint]()
            }
            effectNode.constraints!.append(constraint)
            
            let targetNode = boneArray[targetBoneNo]
            self.ikArray.append(targetNode)
            */
        }
    }
    
    private func readFace() {
        self.faceCount = Int(getUnsignedShort())
        
        let zeroArray = [Float32](count: self.vertexArray.count, repeatedValue: 0)
        
        // read base face
        if self.faceCount > 0 {
            let name = String(getString(20)!) // must be "base"
            var faceVertex = zeroArray
            
            let numVertices = getUnsignedInt()
            let type = getUnsignedByte()
            
            for _ in 0..<numVertices {
                let index = Int(getUnsignedInt())
                self.faceIndexArray.append(index)
                
                let vertexIndex = index * 3
                
                let x = getFloat()
                let y = getFloat()
                let z = -getFloat()
                
                faceVertex[vertexIndex + 0] = x
                faceVertex[vertexIndex + 1] = y
                faceVertex[vertexIndex + 2] = z
            }
            self.faceNameArray.append(name)
            self.faceVertexArray.append(faceVertex)
        }
        
        
        for _ in 1..<self.faceCount {
            let name = String(getString(20)!)
            var faceVertex = zeroArray
            print("faceName: \(name)")
            
            let numVertices = getUnsignedInt()
            
            // 0: base, 1: eyebrows, 2: eyes, 3: lips, 4: etc
            let type = getUnsignedByte()
            
            for _ in 0..<numVertices {
                let index = self.faceIndexArray[Int(getUnsignedInt())]
                let vertexIndex = index * 3
                
                let x = getFloat()
                let y = getFloat()
                let z = -getFloat()
                
                faceVertex[vertexIndex + 0] = x
                faceVertex[vertexIndex + 1] = y
                faceVertex[vertexIndex + 2] = z
            }
            
            self.faceNameArray.append(name)
            self.faceVertexArray.append(faceVertex)
        }
    }
    
    private func createFaceMorph() {
        let morpher = SCNMorpher()
        morpher.calculationMode = .Additive
        
        /*
        let zeroNormalArray = [Float32](count: self.normalArray.count, repeatedValue: 0)
        let zeroNormalData = NSData(bytes: zeroNormalArray, length: 4 * 3 * self.vertexCount)
        let zeroNormalSource = SCNGeometrySource(data: zeroNormalData, semantic: SCNGeometrySourceSemanticNormal, vectorCount: Int(self.vertexCount), floatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        
        let zeroTexcoordArray = [Float32](count: self.texcoordArray.count, repeatedValue: 0)
        let zeroTexcoordData = NSData(bytes: zeroTexcoordArray, length: 4 * 2 * self.vertexCount)
        let zeroTexcoordSource = SCNGeometrySource(data: zeroTexcoordData, semantic: SCNGeometrySourceSemanticTexcoord, vectorCount: Int(self.vertexCount), floatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        */
        
        //let zeroElementArray = self.elementArray
        
        /*
        for index in 0..<self.faceCount {
        let faceVertexData = NSData(bytes: self.faceVertexArray[index], length: 4 * 3 * self.vertexCount)
        let faceVertexSource = SCNGeometrySource(data: faceVertexData, semantic: SCNGeometrySourceSemanticVertex, vectorCount: Int(self.vertexCount), floatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        
        // TODO: create normal source
        
        //let faceGeometry = SCNGeometry(sources: [faceVertexSource, zeroNormalSource, zeroTexcoordSource], elements: self.elementArray)
        let faceGeometry = SCNGeometry(sources: [faceVertexSource], elements: [])
        //faceGeometry.materials = self.materialArray
        faceGeometry.name = self.faceNameArray[index]
        
        morpher.targets.append(faceGeometry)
        }
        */
        let geometryNode = self.workingNode.childNodeWithName("Geometry", recursively: true)
        //geometryNode!.morpher = morpher
        
        let vertexCount = self.vertexArray.count
        let faceVertex = [Float32](count: vertexCount, repeatedValue: 1.0)
        let faceVertexData = NSData(bytes: faceVertex, length: 4 * vertexCount)
        let faceVertexSource = SCNGeometrySource(data: faceVertexData, semantic: SCNGeometrySourceSemanticVertex, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        let faceGeometry = SCNGeometry(sources: [faceVertexSource], elements: [])
        faceGeometry.name = "faceGeometry"
        
        morpher.targets.append(faceGeometry)
        geometryNode!.morpher = morpher
        geometryNode!.morpher!.setWeight(1.0, forTargetAtIndex: 0)
        
        /*
        for index in 0..<geometryNode!.morpher!.targets.count {
        geometryNode!.morpher!.setWeight(1.0, forTargetAtIndex: index)
        }
        */
        /*
        for index in 0..<geometryNode!.morpher!.targets.count {
        geometryNode!.morpher!.setWeight(0.0, forTargetAtIndex: index)
        }
        */
        
        // for debug
        /*
        print("vertexCount = \(self.vertexCount)")
        print("vertexArray.count = \(self.vertexArray.count)")
        
        if self.vertexArray.count != self.faceVertexArray[3].count {
        print("vertexArray count is different: \(self.vertexArray.count) != \(self.faceVertexArray[3].count)")
        }
        for index in 0..<self.vertexArray.count {
        self.vertexArray[index] += self.faceVertexArray[3][index]
        }
        let vertexData = NSData(bytes: self.vertexArray, length: 4 * 3 * self.vertexCount)
        self.vertexSource = SCNGeometrySource(data: vertexData, semantic: SCNGeometrySourceSemanticVertex, vectorCount: Int(self.vertexCount), floatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        */
        /*
        let geometry = SCNGeometry(sources: [self.vertexSource, self.normalSource, self.texcoordSource], elements: self.elementArray)
        geometry.materials = self.materialArray
        geometry.name = "Geometry"
        
        let newGeometryNode = SCNNode(geometry: geometry)
        newGeometryNode.name = "Geometry"
        
        let boneIndicesData = NSData(bytes: self.boneIndicesArray, length: 2 * 2 * self.vertexCount)
        let boneWeightsData = NSData(bytes: self.boneWeightsArray, length: 4 * 2 * self.vertexCount)
        let boneIndicesSource = SCNGeometrySource(data: boneIndicesData, semantic: SCNGeometrySourceSemanticBoneIndices, vectorCount: Int(vertexCount), floatComponents: false, componentsPerVector: 2, bytesPerComponent: 2, dataOffset: 0, dataStride: 4)
        let boneWeightsSource = SCNGeometrySource(data: boneWeightsData, semantic: SCNGeometrySourceSemanticBoneWeights, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        
        let skinner = SCNSkinner(baseGeometry: geometry, bones: self.boneArray, boneInverseBindTransforms: self.boneInverseMatrixArray, boneWeights: boneWeightsSource, boneIndices: boneIndicesSource)
        
        newGeometryNode.skinner = skinner
        newGeometryNode.skinner!.skeleton = self.rootBone
        
        //self.workingNode.name = "rootNode" // FIXME: set model name or file name
        geometryNode!.removeFromParentNode()
        self.workingNode.addChildNode(newGeometryNode)
        
        //geometryNode!.geometry = geometry
        */
    }
    
    private func readDisplayInfo() {
        // read face display info
        self.faceDisplayCount = Int(getUnsignedByte())
        
        for _ in 0..<faceDisplayCount {
            let index = getUnsignedShort()
        }
        
        // read bone display name
        self.boneDisplayNameCount = Int(getUnsignedByte())
        
        for _ in 0..<boneDisplayNameCount {
            let name = getString(50)
        }
        
        // read bone display
        self.boneDisplayCount = Int(getUnsignedInt())
        
        for _ in 0..<boneDisplayCount {
            let index = getUnsignedShort()
            let frameIndex = getUnsignedByte()
        }
    }
    
    private func readEnglishInfo() {
        // read english
        let englishCompatibility = getUnsignedByte()
        
        // read english header
        let englishHeaderName = getString(20)
        let englishComment = getString(256)
        
        // read english bone name
        for _ in 0..<boneCount {
            let englishBoneName = getString(20)
        }
        
        // read english face name
        for _ in 0..<self.faceDisplayCount {
            let englishFaceName = getString(20)
        }
        
        // read english bone name
        for _ in 0..<self.boneDisplayNameCount {
            let englishBoneDisplayName = getString(50)
        }
    }
    
    private func readToonTexture() {
        for _ in 0...9 {
            let textureFileName = getString(100)
        }
    }
    
    private func readPhysicsBody() {
        self.physicsBodyCount = Int(getUnsignedInt())
        let gravity = SCNPhysicsField()
        
        for _ in 0..<self.physicsBodyCount {
            let name = getString(20)!
            let boneIndex = Int(getUnsignedShort())
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
                bodyType = SCNPhysicsBodyType.Kinematic
            } else if type == 1 {
                bodyType = SCNPhysicsBodyType.Dynamic
            } else if type == 2 {
                bodyType = SCNPhysicsBodyType.Dynamic
            }
            bodyType = SCNPhysicsBodyType.Kinematic // for debug
            
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
            
            body.affectedByGravity = true
            body.mass = weight
            body.friction = friction
            body.rollingFriction = rotateDim
            body.collisionBitMask = groupTarget
            body.restitution = recoil
            body.usesDefaultMomentOfInertia = true
            
            if boneIndex != 0xFFFF {
                let bone = self.boneArray[boneIndex]
                bone.physicsBody = body
            }
            
            self.physicsBodyArray.append(body)
        }
    }
    
    private func readConstraint() {
        var constraintCount = getUnsignedInt()
        
        for _ in 0..<constraintCount {
            let name = getString(20)
            let etcData = getData(104)
        }
    }
    
    private func createGeometry() {
        // FIXME: delete  debug
        /*
        for index in 0..<self.vertexArray.count {
        let d = self.faceVertexArray[8][index]
        
        if d != 0 {
        print("[\(index)]: \(d)")
        print("  before: \(self.vertexArray[index])")
        
        self.vertexArray[index] += d
        
        print("  after : \(self.vertexArray[index])")
        }
        }
        */
        
        let vertexData = NSData(bytes: self.vertexArray, length: 4 * 3 * self.vertexCount)
        let normalData = NSData(bytes: self.normalArray, length: 4 * 3 * self.vertexCount)
        let texcoordData = NSData(bytes: self.texcoordArray, length: 4 * 2 * self.vertexCount)
        let boneIndicesData = NSData(bytes: self.boneIndicesArray, length: 2 * 2 * self.vertexCount)
        let boneWeightsData = NSData(bytes: self.boneWeightsArray, length: 4 * 2 * self.vertexCount)
        //let edgeData = NSData(bytes: self.edgeArray, length: 1 * 1 * self.vertexCount)
        let indexData = NSData(bytes: self.indexArray, length: 2 * self.indexCount)
        
        self.vertexSource = SCNGeometrySource(data: vertexData, semantic: SCNGeometrySourceSemanticVertex, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        self.normalSource = SCNGeometrySource(data: normalData, semantic: SCNGeometrySourceSemanticNormal, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        self.texcoordSource = SCNGeometrySource(data: texcoordData, semantic: SCNGeometrySourceSemanticTexcoord, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        let boneIndicesSource = SCNGeometrySource(data: boneIndicesData, semantic: SCNGeometrySourceSemanticBoneIndices, vectorCount: Int(vertexCount), floatComponents: false, componentsPerVector: 2, bytesPerComponent: 2, dataOffset: 0, dataStride: 4)
        let boneWeightsSource = SCNGeometrySource(data: boneWeightsData, semantic: SCNGeometrySourceSemanticBoneWeights, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        
        
        var indexPos = 0
        for index in 0..<self.materialCount {
            let count = materialIndexCountArray[index]
            let length = count * 2
            let data =  indexData.subdataWithRange(NSRange.init(location: indexPos, length: length))
            
            let element = SCNGeometryElement(data: data, primitiveType: .Triangles, primitiveCount: count / 3, bytesPerIndex: 2)
            
            /*
            if(index == 2) {
            print("********** Element \(index) **********")
            for i in 0..<count {
            var vertexNum: Int16 = 0
            let token = data.subdataWithRange(NSRange.init(location: i*2, length: 2))
            token.getBytes(&vertexNum, length: 2)
            
            let vertexNumInt = Int(vertexNum)
            
            let posX = self.vertexArray[vertexNumInt * 3]
            let posY = self.vertexArray[vertexNumInt * 3 + 1]
            let posZ = self.vertexArray[vertexNumInt * 3 + 2]
            
            let bone1 = self.boneIndicesArray[vertexNumInt * 2]
            let bone2 = self.boneIndicesArray[vertexNumInt * 2 + 1]
            
            let weight1 = self.boneWeightsArray[vertexNumInt * 2]
            let weight2 = self.boneWeightsArray[vertexNumInt * 2 + 1]
            
            print("v[\(vertexNumInt)]: pos(\(posX), \(posY), \(posZ)), bone(\(bone1), \(bone2)), weight(\(weight1), \(weight2))")
            }
            }
            */
            
            /*
            if(index != 2) {
            elementArray.append(element)
            }else {
            let emptyElement = SCNGeometryElement(data: NSData(), primitiveType: .Triangles, primitiveCount: 0, bytesPerIndex: 2)
            elementArray.append(emptyElement)
            }
            */
            self.elementArray.append(element)
            
            indexPos += length
        }
        
        let geometry = SCNGeometry(sources: [self.vertexSource, self.normalSource, self.texcoordSource], elements: self.elementArray)
        geometry.materials = self.materialArray
        geometry.name = "Geometry"
        
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.name = "Geometry"
        
        let skinner = SCNSkinner(baseGeometry: geometry, bones: self.boneArray, boneInverseBindTransforms: self.boneInverseMatrixArray, boneWeights: boneWeightsSource, boneIndices: boneIndicesSource)
        
        geometryNode.skinner = skinner
        geometryNode.skinner!.skeleton = self.rootBone
        
        self.workingNode.name = "rootNode" // FIXME: set model name or file name
        self.workingNode.addChildNode(geometryNode)
        self.workingNode.addChildNode(self.rootBone)
        
        //showBoneTree(self.rootBone)
    }
}