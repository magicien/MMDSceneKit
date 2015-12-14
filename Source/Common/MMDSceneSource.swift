//
//  MMDSceneSource.swift
//  MMDSceneKit
//
//  Created by magicien on 12/9/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

#if os(iOS)
        import UIKit
#elseif os(OSX)
        import AppKit
#endif


public enum MMDFileType {
    case PMM, PMD, VMD, X, PMX, UNKNOWN
}

public class MMDSceneSource: SCNSceneSource {
    
    /// file type which is detected by file header
    public private(set) var fileType: MMDFileType! = .UNKNOWN
    
    private var directoryPath: String! = nil
    private var binaryData: NSData! = nil
    private var length = 0
    private var pos = 0
    
    private var workingScene: SCNScene! = nil
    private var workingNode: MMDNode! = nil
    
    // MARK: - property for PMD File
    
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
    
    // MARK: display info data
    private var faceDisplayCount = 0
    private var boneDisplayNameCount = 0
    private var boneDisplayCount = 0
    
    // MARK: physics body data
    private var physicsBodyCount = 0
    private var physicsBodyArray: [SCNPhysicsBody]! = nil

    
    
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
    
    // MARK: camera motion data
    
    // MARK: light motion data
    
    // MARK: shadow data
    
    // MARK: visibility and IK data
    
    
    // MARK: - property for PMM File
    
    
    // MARK: - Initialize
    public override init() {
        super.init()
    }
    
    /**
        Initializes a scene source for reading the scene graph contained in an NSData object.
        - parameter data: A data object containing a scene file in MMD file format.
        - parameter options: ignored. just for compatibility of SCNSceneSource.
    */
    public override convenience init?(data: NSData, options: [String : AnyObject]? = nil) {
        self.init()
        self.loadData(data, options: options)
    }
    
    private func loadData(data: NSData, options: [String : AnyObject]?) {
        self.binaryData = data
        self.length = data.length
        self.pos = 0
        
        self.workingScene = SCNScene()
        
        checkFileTypeFromData()
        if self.fileType == .PMD {
            if let pmdNode = loadPMDFile() {
                self.workingScene.rootNode.addChildNode(pmdNode)
            }
        }else if self.fileType == .VMD {
            if let vmdNode = loadVMDFile() {
                self.workingScene.rootNode.addChildNode(vmdNode)
            }
        }else if self.fileType == .PMM {
            if let pmmNodes = loadPMMFile() {
                for node in pmmNodes {
                    self.workingScene.rootNode.addChildNode(node)
                }
            }
        }else if self.fileType == .X {
            if let xNode = loadXFile() {
                self.workingScene.rootNode.addChildNode(xNode)
            }
        }else if self.fileType == .PMX {
            if let pmxNode = loadPMDFile() {
                self.workingScene.rootNode.addChildNode(pmxNode)
            }
        }else{
            // unknown file
        }
    }

    
    /**
        Initializes a scene source for reading the scene graph from a specified file.
        - parameter url: A URL identifying the location of a scene file in MMD file format.
        - parameter options: ignored. just for compatibility of SCNSceneSource.
    */
    public override convenience init?(URL url: NSURL, options: [String : AnyObject]? = nil) {
        self.init()
    }

    /**
        Initializes a scene source for reading the scene graph from a specified file.
        - parameter url: A URL identifying the location of a scene file in MMD file format.
        - parameter options: ignored. just for compatibility of SCNSceneSource.
    */
    public convenience init?(path: String, options: [String : AnyObject]? = nil) {
        self.init()
        self.directoryPath = (path as NSString).stringByDeletingLastPathComponent

        let data = NSData(contentsOfFile: path)
        if data == nil {
            print("data is nil...")
        } else {
            self.loadData(data!, options: options)
        }
    }
    
    /**
        Return an array of MMDNode objects which represent model node
    */
    public func modelNodes() -> [MMDNode]! {
        var nodeArray = [MMDNode]()
        
        if self.fileType == .PMD || self.fileType == .PMX {
            print("add workingNode: \(self.workingNode)")
            nodeArray.append(self.workingNode) // FIXME: clone node
        }else if self.fileType == .PMM {
            for node in self.workingScene.rootNode.childNodes {
                if let mmdNode = node as? MMDNode {
                    nodeArray.append(mmdNode) // FIXME: clone node
                }
            }
        }
        
        return nodeArray
    }

    public func cameraNodes() -> [MMDNode]! {
        let cameraArray = [MMDNode]()
        
        return cameraArray
    }
    
    public func lightNodes() -> [MMDNode]! {
        let lightArray = [MMDNode]()
        
        return lightArray
    }
    

    /**
        Return a hash of CAAnimationGroup
    */
    public func animations() -> [String: CAAnimationGroup]! {
        var animationHash = [String: CAAnimationGroup]()
    
        /*
        // search animations among 1st level nodes
        for node in self.workingScene.rootNode.childNodes {
            for animKey in node.animationKeys {
                if let animation = node.animationForKey(animKey) as? CAAnimationGroup {
                    animationHash[animKey] = animation // FIXME: avoiding conflict
                    node.removeAnimationForKey(animKey) // FIXME
                }
            }
        }
        */
        animationHash["animation"] = self.workingAnimationGroup // FIXME
        
        return animationHash
    }
    
    
    private func checkFileTypeFromData() -> MMDFileType! {
        let byte3 = self.binaryData.subdataWithRange(NSRange.init(location: 0, length: 3))
        let str3 = NSString.init(data: byte3, encoding: NSShiftJISStringEncoding)

        if str3 == "Pmd" {
            self.fileType = .PMD
            return .PMD
        }

        let byte4 = self.binaryData.subdataWithRange(NSRange.init(location: 0, length: 4))
        let str4 = NSString.init(data: byte4, encoding: NSShiftJISStringEncoding)

        if str4 == "xof " {
            self.fileType = .X
            return .X
        }
        if str4 == "PMX " {
            self.fileType = .PMX
            return .PMX
        }
        
        let byte24 = self.binaryData.subdataWithRange(NSRange.init(location: 0, length: 24))
        let str24 = NSString.init(data: byte24, encoding: NSShiftJISStringEncoding)

        if str24 == "Polygon Movie maker 0002" {
            self.fileType = .PMM
            return .PMM
        }

        let byte25 = self.binaryData.subdataWithRange(NSRange.init(location: 0, length: 25))
        let str25 = NSString.init(data: byte25, encoding: NSShiftJISStringEncoding)

        if str25 == "Vocaloid Motion Data 0002" {
            self.fileType = .VMD
            return self.fileType
        }
        
        self.fileType = .UNKNOWN
        return .UNKNOWN
    }
    
    // MARK: - Loading PMM File
    
    private func loadPMMFile() -> [MMDNode]? {
        return nil
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
        
        for _ in 0..<self.faceCount {
            let name = getString(20)!
            print("faceName: \(name)")
            
            let numVertices = getUnsignedInt()
            let type = getUnsignedByte()
            
            for _ in 0..<numVertices {
                let index = getUnsignedInt()
                let x = getFloat()
                let y = getFloat()
                let z = getFloat()
            }
        }
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
        let vertexData = NSData(bytes: self.vertexArray, length: 4 * 3 * self.vertexCount)
        let normalData = NSData(bytes: self.normalArray, length: 4 * 3 * self.vertexCount)
        let texcoordData = NSData(bytes: self.texcoordArray, length: 4 * 2 * self.vertexCount)
        let boneIndicesData = NSData(bytes: self.boneIndicesArray, length: 2 * 2 * self.vertexCount)
        let boneWeightsData = NSData(bytes: self.boneWeightsArray, length: 4 * 2 * self.vertexCount)
        //let edgeData = NSData(bytes: self.edgeArray, length: 1 * 1 * self.vertexCount)
        let indexData = NSData(bytes: self.indexArray, length: 2 * self.indexCount)
        
        let vertexSource = SCNGeometrySource(data: vertexData, semantic: SCNGeometrySourceSemanticVertex, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        let normalSource = SCNGeometrySource(data: normalData, semantic: SCNGeometrySourceSemanticNormal, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        let texcoordSource = SCNGeometrySource(data: texcoordData, semantic: SCNGeometrySourceSemanticTexcoord, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        let boneIndicesSource = SCNGeometrySource(data: boneIndicesData, semantic: SCNGeometrySourceSemanticBoneIndices, vectorCount: Int(vertexCount), floatComponents: false, componentsPerVector: 2, bytesPerComponent: 2, dataOffset: 0, dataStride: 4)
        let boneWeightsSource = SCNGeometrySource(data: boneWeightsData, semantic: SCNGeometrySourceSemanticBoneWeights, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        
        
        var elementArray = [SCNGeometryElement]()
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
            elementArray.append(element)
            
            indexPos += length
        }
        
        let geometry = SCNGeometry(sources: [vertexSource, normalSource, texcoordSource], elements: elementArray)
        geometry.materials = materialArray
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
    
    
    // MARK: - Loading VMD File
    
    /**
    */
    private func loadVMDFile() -> MMDNode? {
        self.workingNode = MMDNode()
        self.workingAnimationGroup = CAAnimationGroup()
        self.workingAnimationGroup.animations = [CAAnimation]()

        self.animationHash = [String: CAKeyframeAnimation]()
        
        self.readVMDHeader()
        self.readFrame()
        self.readFaceMotion()
        self.createAnimations()

        // FIXME: avoid key conflict
        //self.workingNode.addAnimation(self.workingAnimationGroup, forKey: "animation")
        //self.workingScene.rootNode.addChildNode(self.workingNode)

        if (self.pos >= self.length) {
            return self.workingNode
        }

        self.readCameraMotion()
        self.readLightMotion()
        
        if (self.pos >= self.length) {
            return self.workingNode
        }

        self.readShadow()

        if (self.pos >= self.length) {
            return self.workingNode
        }

        self.readVisibilityAndIK()

        if (self.pos >= self.length) {
            return self.workingNode
        }
        
        return self.workingNode
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
        
        let easeInEaseOutFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseInEaseOut)
        
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
            let posZ = NSNumber(float: getFloat())
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
        
        for _ in 0..<faceFrameCount {
            let name = getString(15)
            let frameNo = getUnsignedInt()
            let factor = getFloat()
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
            
            /*
            if(motion.keyPath!.hasSuffix(".quaternion") ||
                motion.keyPath!.hasSuffix(".x")) {
                let count = motion.keyTimes!.count
                //print("count: \(count)")
                
                self.workingAnimationGroup.animations!.append(motion)
                //print("\(motion.keyPath!) added")
            }
            */
            
            self.workingAnimationGroup.animations!.append(motion)
        }
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
    

    // MARK: - Loading X File
    
    /**
    */
    private func loadXFile() -> MMDNode? {
        return nil
    }
    
    
    // MARK: - Loading PMX File
    
    /**
    */
    private func loadPMXFile() -> MMDNode? {
        return nil
    }
    
    
    // MARK: - Utility functions

    /**
        get String data from MMD/PMD/VMD file
        - parameter length: length of data you want to get (unit is byte)
        - parameter encoding: encoding of string data. Default encoding of .mmd file is ShiftJIS
        - returns: String data
    */
    private func getString(length: Int, encoding: UInt = NSShiftJISStringEncoding) -> NSString? {
        // check where null char is
        var strlen = length
        var chars = Array<Int8>(count: length, repeatedValue: 0)
        self.binaryData.getBytes(&chars, range: NSRange.init(location: self.pos, length: length))
        
        for index in 0..<length {
            if (chars[index] == 0) {
                strlen = index
                break
            }
        }
        
        // encode string
        let token = self.binaryData.subdataWithRange(NSRange.init(location: self.pos, length: strlen))
        let str = NSString.init(data: token, encoding: encoding)
        
        self.pos += length
        
        return str
    }
    
    /**
        read UInt8 data and return Int value from file
        - returns: UInt8 data
    */
    private func getUnsignedByte() -> UInt8 {
        var num: UInt8 = 0
        let token = self.binaryData.subdataWithRange(NSRange.init(location: self.pos, length: 1))
        token.getBytes(&num, length: 1)
        self.pos += 1
        
        return num
    }
    
    /**
     read UInt8 data and return Int value from file
     - returns: UInt16 data
     */
    private func getUnsignedShort() -> UInt16 {
        var num: UInt16 = 0
        let token = self.binaryData.subdataWithRange(NSRange.init(location: self.pos, length: 2))
        token.getBytes(&num, length: 2)
        self.pos += 2
        
        return num
    }
    
    /**
     read UInt32 data and return Int value from file
     - returns: UInt32 data
     */
    private func getUnsignedInt() -> UInt32 {
        var num: UInt32 = 0
        let token = self.binaryData.subdataWithRange(NSRange.init(location: self.pos, length: 4))
        token.getBytes(&num, length: 4)
        self.pos += 4
        
        return num
    }
    
    /**
     read Int32 data and return Int value from file
     - returns: Signed Int32 data
     */
    private func getInt() -> Int32 {
        var num: Int32 = 0
        let token = self.binaryData.subdataWithRange(NSRange.init(location: self.pos, length: 4))
        token.getBytes(&num, length: 4)
        self.pos += 4
        
        return num
    }
    
    /**
     read Float32 data and return Int value from file
     - returns: Float data
     */
    private func getFloat() -> Float32 {
        var num: Float32 = 0
        let token = self.binaryData.subdataWithRange(NSRange.init(location: self.pos, length: 4))
        token.getBytes(&num, length: 4)
        self.pos += 4
        
        return num
    }
    
    /**
     read binary data and return NSData from file
     - parameter length: length of data you want to get (unit is byte)
     - returns: NSData value
     */
    private func getData(length: Int) -> NSData {
        let data = self.binaryData.subdataWithRange(NSRange.init(location: self.pos, length: length))
        self.pos += length
        
        return data
    }
    
    /**
     normalize SCNVector4 or SCNQuaternion value.
     - parameter quat: data which has to be normalized. This variable is changed by this function.
     */
    private func normalize(inout quat: SCNVector4) {
        let x2 = quat.x * quat.x
        let y2 = quat.y * quat.y
        let z2 = quat.z * quat.z
        let w2 = quat.w * quat.w
        
        let r = sqrt(x2 + y2 + z2 + w2)
        if r == 0 {
            // impossible to normalize
            return
        }
        let invr = 1.0 / r
        
        quat.x *= invr
        quat.y *= invr
        quat.z *= invr
        quat.w *= invr
    }
    
    // MARK: - for Debug

    /**
    show bone tree for debug
    - parameter bone: root node of the bone tree
    - parameter prefix: prefix for indent
    */
    private func showBoneTree(bone: SCNNode, prefix: String = "") {
        print(prefix + bone.name! + "(\(bone.position.x), \(bone.position.y), \(bone.position.z))")
        
        for child in bone.childNodes {
            showBoneTree(child, prefix: "    " + prefix)
        }
    }
}
