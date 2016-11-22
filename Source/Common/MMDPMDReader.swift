//
//  MMDPMDReader.swift
//  MMDSceneKit
//
//  Created by magicien on 12/18/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

// define for macro
public let MMD_USES_SCNMORPHER = true

import SceneKit

class MMDPMDReader: MMDReader {
    fileprivate var workingNode: MMDNode! = nil
    
    // MARK: PMD header data
    fileprivate var pmdMagic: String! = ""
    fileprivate var version: Float = 0.0
    fileprivate var modelName: String! = ""
    fileprivate var comment: String! = ""
    
    // MARK: vertex data
    fileprivate var vertexCount = 0
    fileprivate var vertexArray: [Float32]! = nil
    fileprivate var normalArray: [Float32]! = nil
    fileprivate var texcoordArray: [Float32]! = nil
    fileprivate var boneIndicesArray: [UInt16]! = nil
    fileprivate var boneWeightsArray: [Float32]! = nil
    
    // MARK: index data
    fileprivate var indexCount = 0
    fileprivate var indexArray: [UInt16]! = nil
    
    // MARK: material data
    fileprivate var materialCount = 0
    fileprivate var materialArray: [SCNMaterial]! = nil
    fileprivate var materialIndexCountArray: [Int]! = nil
    
    // MARK: bone data
    fileprivate var boneCount = 0
    fileprivate var boneArray: [MMDNode]! = nil
    fileprivate var boneInverseMatrixArray: [NSValue]! = nil
    fileprivate var rootBone: MMDNode! = nil
    fileprivate var boneHash: [String:MMDNode]! = nil
    
    // MARK: IK data
    fileprivate var ikCount = 0
    //private var ikArray: [MMDNode]! = nil
    
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
    
    /**
     
    */
    static func getNode(_ data: Data, directoryPath: String! = "") -> MMDNode? {
        let reader = MMDPMDReader(data: data, directoryPath: directoryPath)
        let node = reader.loadPMDFile()
        
        return node
    }
    
    // MARK: - Loading PMD File
    /**
     * load .pmd file
     * - return: 
     */
    fileprivate func loadPMDFile() -> MMDNode? {
        // initialize working variables
        self.workingNode = MMDNode()
        //self.workingNode.ikOn = true
        
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
        self.workingNode.ikArray = [MMDIKConstraint]()
        
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
    fileprivate func readPMDHeader() {
        self.pmdMagic = String(getString(length: 3)!)
        print("pmdMagic: \(pmdMagic)")
        self.version = Float(getFloat())
        self.modelName = String(describing: getString(length: 20))
        self.comment = String(describing: getString(length: 256))
    }
    
    /**
     read PMD vertex data
     */
    fileprivate func readVertex() {
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
    
    fileprivate func readIndex() {
        self.indexCount = Int(getUnsignedInt())
        
        for _ in 0..<(self.indexCount/3) {
            let index1 = getUnsignedShort()
            let index2 = getUnsignedShort()
            let index3 = getUnsignedShort()
            
            // we have to change the index order because of the coordination difference.
            self.indexArray.append(index1)
            self.indexArray.append(index3)
            self.indexArray.append(index2)
        }
    }
    
    fileprivate func readMaterial() {
        self.materialCount = Int(getUnsignedInt())
        
        for _ in 0..<self.materialCount {
            let material = SCNMaterial()
            
            #if os(iOS) || os(tvOS) || os(watchOS)
                
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
            let textureFile = getString(length: 20)
            
            print("textureFileName: \(textureFile)")
            if textureFile != "" {
                let fileName = (self.directoryPath as NSString).appendingPathComponent(String(textureFile!))
                
                print("setTexture: \(fileName)")
                
                #if os(iOS) || os(tvOS) || os(watchOS)
                    material.diffuse.contents = UIImage(contentsOfFile: fileName)
                #elseif os(OSX)
                    material.diffuse.contents = NSImage(contentsOfFile: fileName)
                #endif
            }
            material.isDoubleSided = true
            
            self.materialIndexCountArray.append(indexCount)
            self.materialArray.append(material)
        }
        
    }
    
    fileprivate func readBone() {
        self.boneCount = Int(getUnsignedShort())
        
        var parentNoArray = [Int]()
        //var boneInverseMatrixData = [NSValue]()
        var bonePositionArray = [SCNVector3]()
        
        self.rootBone.position = SCNVector3Make(0, 0, 0)
        self.rootBone.name = "rootBone"
        
        for index in 0..<self.boneCount {
            let boneNode = MMDNode()
            boneNode.name = String(getString(length: 20)!)

            if let boneName = boneNode.name {
                let maxLen = boneName.characters.count
                if maxLen >= 3 {
                    let kneeName = (boneName as NSString).substring(to: 3)
                    if kneeName == "右ひざ" || kneeName == "左ひざ" {
                        boneNode.isKnee = true
                    }
                }
            }
            
            let parentNo = Int(getUnsignedShort())
            parentNoArray.append(parentNo)
            
            let childNo = getUnsignedShort()
            let type = getUnsignedByte()
            let ikTarget = getUnsignedShort()
            
            switch(type) {
            case 0:
                boneNode.type = .rotate
            case 1:
                boneNode.type = .rotate_TRANSLATE
            case 2:
                boneNode.type = .ik
            case 3:
                boneNode.type = .unknown
            case 4:
                boneNode.type = .ik_CHILD
            case 5:
                boneNode.type = .rotate_CHILD
            case 6:
                boneNode.type = .ik_TARGET
            case 7:
                boneNode.type = .hidden
            case 8:
                boneNode.type = .twist
            case 9:
                boneNode.type = .roll
            default:
                boneNode.type = .unknown
            }
            
            #if os(iOS) || os(tvOS) || os(watchOS)
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
            
            self.boneInverseMatrixArray.append(NSValue.init(scnMatrix4: matrix))
        }
        
        self.boneArray.append(self.rootBone)
        self.boneInverseMatrixArray.append(NSValue.init(scnMatrix4: SCNMatrix4Identity))

        //self.boneArray.append(self.workingNode)
        //self.boneInverseMatrixArray.append(NSValue.init(SCNMatrix4: SCNMatrix4Identity))
        
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
    }
    
    
    
    fileprivate func readIK() {
        self.ikCount = Int(getUnsignedShort())
        
        for _ in 0..<self.ikCount {
            let ik = MMDIKConstraint()
            
            let ikBoneNo = Int(getUnsignedShort())
            let targetBoneNo = Int(getUnsignedShort())
            let numLink = getUnsignedByte()
            let iteration = getUnsignedShort()
            let weight = getFloat()

            ik.ikBone = self.boneArray[ikBoneNo]
            ik.targetBone = self.boneArray[targetBoneNo]
            ik.iteration = Int(iteration)
            ik.weight = Float(Double(weight) * M_PI)
            ik.boneArray = [MMDNode]()
            
            print("targetBoneNo: \(targetBoneNo) \(ik.targetBone.name!), ikBoneNo: \(ikBoneNo) \(ik.ikBone.name!)")
            for _ in 0..<numLink {
                let linkNo = Int(getUnsignedShort())
                let bone = self.boneArray[linkNo]

                print("linkNo: \(linkNo), \(bone.name!)")

                ik.boneArray.append(bone)
            }
            self.workingNode.ikArray!.append(ik)
            
            let constraint = SCNIKConstraint.inverseKinematicsConstraint(chainRootNode: ik.boneArray.last!)
            
            ik.printInfo()
            /*
            let effectorNode = self.boneArray[effectorBoneNo]
            if effectorNode.constraints == nil {
                effectorNode.constraints = [SCNConstraint]()
            }
            effectorNode.constraints!.append(constraint)
            //effectorNode.ikConstraint = constraint
            
            let targetNode = self.boneArray[targetBoneNo]
            self.ikArray.append(targetNode)
            
            let targetConstraint = SCNTransformConstraint(inWorldSpace: true, withBlock: { (node, matrix) -> SCNMatrix4 in
                if let mmdNode = node as? MMDNode {
                    //mmdNode.ikTargetBone!.ikConstraint!.targetPosition.x = matrix.m41
                    //mmdNode.ikTargetBone!.ikConstraint!.targetPosition.y = matrix.m42
                    //mmdNode.ikTargetBone!.ikConstraint!.targetPosition.z = matrix.m43
                    //mmdNode.ikTargetBone!.ikConstraint!.targetPosition = mmdNode.presentationNode.position
                    
                    //print("presentation: \(mmdNode.presentationNode.position), matrix: (\(matrix.m41), \(matrix.m42), \(matrix.m43))")
                }
                
                return matrix
            })

            if targetNode.constraints == nil {
                targetNode.constraints = [SCNConstraint]()
            }
            targetNode.constraints!.append(targetConstraint)
            
            targetNode.ikTargetBone = effectorNode
            */
            
        }
    }
    
    fileprivate func calcKneeConstraint(_ mat: SCNMatrix4) -> SCNMatrix4 {
        var x = atan2( Double(mat.m23), Double(mat.m33) )

        let minX = 0.003
        let maxX = M_PI - 0.003
        if x < minX {
            x = minX
        }
        if x > maxX {
            x = maxX
        }
        
        var newMat = SCNMatrix4MakeRotation(OSFloat(x), 1, 0, 0)
        newMat.m41 = mat.m41
        newMat.m42 = mat.m42
        newMat.m43 = mat.m43
        
        return newMat
    }
    
    fileprivate func readFace() {
        self.faceCount = Int(getUnsignedShort())
        
        let zeroArray = [Float32](repeating: 0, count: self.vertexArray.count)
        
        // read base face
        if self.faceCount > 0 {
            let name = String(getString(length: 20)!) // must be "base"
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
            let name = String(getString(length: 20)!)
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
    
    fileprivate func createFaceMorph() {
        let morpher = SCNMorpher()
        morpher.calculationMode = .additive

        for index in 0..<self.faceCount {
            let faceVertexData = NSData(bytes: self.faceVertexArray[index], length: 4 * 3 * self.vertexCount)
            let faceVertexSource = SCNGeometrySource(data: faceVertexData as Data, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: Int(self.vertexCount), usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
            
            //let faceGeometry = SCNGeometry(sources: [faceVertexSource], elements: [])
            let faceGeometry = SCNGeometry(sources: [faceVertexSource, self.normalSource], elements: [])
            faceGeometry.name = self.faceNameArray[index]
            
            morpher.targets.append(faceGeometry)
        }
        let geometryNode = self.workingNode.childNode(withName: "Geometry", recursively: true)
        geometryNode!.morpher = morpher
        
        // FIXME
        self.workingNode.geometryMorpher = morpher
    }
    
    fileprivate func readDisplayInfo() {
        // read face display info
        self.faceDisplayCount = Int(getUnsignedByte())
        
        for _ in 0..<faceDisplayCount {
            let index = getUnsignedShort()
        }
        
        // read bone display name
        self.boneDisplayNameCount = Int(getUnsignedByte())
        
        for _ in 0..<boneDisplayNameCount {
            let name = getString(length: 50)
        }
        
        // read bone display
        self.boneDisplayCount = Int(getUnsignedInt())
        
        for _ in 0..<boneDisplayCount {
            let index = getUnsignedShort()
            let frameIndex = getUnsignedByte()
        }
    }
    
    fileprivate func readEnglishInfo() {
        // read english
        let englishCompatibility = getUnsignedByte()
        
        // read english header
        let englishHeaderName = getString(length: 20)
        let englishComment = getString(length: 256)
        
        // read english bone name
        for _ in 0..<boneCount {
            let englishBoneName = getString(length: 20)
        }
        
        // read english face name
        for _ in 0..<self.faceDisplayCount {
            let englishFaceName = getString(length: 20)
        }
        
        // read english bone name
        for _ in 0..<self.boneDisplayNameCount {
            let englishBoneDisplayName = getString(length: 50)
        }
    }
    
    fileprivate func readToonTexture() {
        for _ in 0...9 {
            let textureFileName = getString(length: 100)
        }
    }
    
    fileprivate func readPhysicsBody() {
        self.physicsBodyCount = Int(getUnsignedInt())
        let gravity = SCNPhysicsField()
        
        for _ in 0..<self.physicsBodyCount {
            let name = getString(length: 20)!
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
                print("unknown physics body shape: \(shapeType)")
            }
            
            
            let body = SCNPhysicsBody(type: bodyType, shape: SCNPhysicsShape(geometry: shape, options: nil))
            
            body.isAffectedByGravity = true
            body.mass = weight
            body.friction = friction
            body.rollingFriction = rotateDim
            body.collisionBitMask = groupTarget
            body.restitution = recoil
            body.usesDefaultMomentOfInertia = true
            
            if boneIndex != 0xFFFF {
                let bone = self.boneArray[boneIndex]
                bone.physicsBody = body
                print("physicsBody: \(name) -> \(bone.name!), (\(dx), \(dy), \(dz))")
            }else{
                print("physicsBody: \(name) -> nil")
            }
            
            self.physicsBodyArray.append(body)
        }
    }
    
    fileprivate func readConstraint() {
        let constraintCount = getUnsignedInt()
        
        for _ in 0..<constraintCount {
            let name = getString(length: 20)
            let bodyANo = Int(getUnsignedInt())
            let bodyBNo = Int(getUnsignedInt())
            
            let bodyA = self.physicsBodyArray[bodyANo]
            let bodyB = self.physicsBodyArray[bodyBNo]
            
            print("===============")
            print("name: \(name), bodyA: \(bodyANo), bodyB: \(bodyBNo)")
            
            let pos = SCNVector3(getFloat(), getFloat(), -getFloat())
            let rot = SCNVector3(getFloat(), getFloat(), -getFloat())
            
            let pos1 = SCNVector3(getFloat(), getFloat(), -getFloat())
            let pos2 = SCNVector3(getFloat(), getFloat(), -getFloat())
            
            let rot1 = SCNVector3(getFloat(), getFloat(), -getFloat())
            let rot2 = SCNVector3(getFloat(), getFloat(), -getFloat())
            
            let spring_pos = SCNVector3(getFloat(), getFloat(), -getFloat())
            let sprint_rot = SCNVector3(getFloat(), getFloat(), -getFloat())
            
            // FIXME: calc rotation
            //let posA = SCNVector3(pos.x - bodyA.
            
            let constraint = SCNPhysicsBallSocketJoint(bodyA: bodyA, anchorA: pos1, bodyB: bodyB, anchorB: pos2)
            
            print("pos: \(pos.x), \(pos.y), \(pos.z)")
            print("rot: \(rot.x), \(rot.y), \(rot.z)")
            print("pos1: \(pos1.x), \(pos1.y), \(pos1.z)")
            print("pos2: \(pos2.x), \(pos2.y), \(pos2.z)")
            print("rot1: \(rot1.x), \(rot1.y), \(rot1.z)")
            print("rot2: \(rot2.x), \(rot2.y), \(rot2.z)")
            
            // FIXME: 
            //self.workingNode.physicsBehaviors.append(constraint)
        }
    }
    
    fileprivate func createGeometry() {
        let vertexData = NSData(bytes: self.vertexArray, length: 4 * 3 * self.vertexCount)
        let normalData = NSData(bytes: self.normalArray, length: 4 * 3 * self.vertexCount)
        let texcoordData = NSData(bytes: self.texcoordArray, length: 4 * 2 * self.vertexCount)
        let boneIndicesData = NSData(bytes: self.boneIndicesArray, length: 2 * 2 * self.vertexCount)
        let boneWeightsData = NSData(bytes: self.boneWeightsArray, length: 4 * 2 * self.vertexCount)
        //let edgeData = NSData(bytes: self.edgeArray, length: 1 * 1 * self.vertexCount)
        let indexData = NSData(bytes: self.indexArray, length: 2 * self.indexCount)
        
        self.vertexSource = SCNGeometrySource(data: vertexData as Data, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        self.normalSource = SCNGeometrySource(data: normalData as Data, semantic: SCNGeometrySource.Semantic.normal, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        self.texcoordSource = SCNGeometrySource(data: texcoordData as Data, semantic: SCNGeometrySource.Semantic.texcoord, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        let boneIndicesSource = SCNGeometrySource(data: boneIndicesData as Data, semantic: SCNGeometrySource.Semantic.boneIndices, vectorCount: Int(vertexCount), usesFloatComponents: false, componentsPerVector: 2, bytesPerComponent: 2, dataOffset: 0, dataStride: 4)
        let boneWeightsSource = SCNGeometrySource(data: boneWeightsData as Data, semantic: SCNGeometrySource.Semantic.boneWeights, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        
        
        var indexPos = 0
        for index in 0..<self.materialCount {
            let count = materialIndexCountArray[index]
            let length = count * 2
            let data =  indexData.subdata(with: NSRange(indexPos..<indexPos+length))
            
            let element = SCNGeometryElement(data: data, primitiveType: .triangles, primitiveCount: count / 3, bytesPerIndex: 2)
            
            self.elementArray.append(element)
            
            indexPos += length
        }

#if !os(watchOS)
        //let program = MMDProgram()
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
        geometryNode.skinner!.skeleton = self.rootBone
        geometryNode.castsShadow = true
        
        //let program = MMDProgram()
        //geometryNode.geometry!.program = program
        
        self.workingNode.name = "rootNode" // FIXME: set model name or file name
        self.workingNode.castsShadow = true
        self.workingNode.addChildNode(geometryNode)
        
        //showBoneTree(self.rootBone)
        
        // FIXME: use morpher
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
    }
}
