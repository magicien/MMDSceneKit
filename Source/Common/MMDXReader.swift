//
//  MMDXReader.swift
//  MMDSceneKit
//
//  Created by magicien on 12/18/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

class MMDXReader : MMDReader {
    fileprivate var workingNode: MMDNode! = nil
    fileprivate var workingGeometry: SCNGeometry! = nil
    fileprivate var workingGeometryNode: SCNNode! = nil
    
    fileprivate var text: String! = nil
    fileprivate var subText: String! = nil
    fileprivate var offset = 0
    fileprivate var err = 0
    
    fileprivate let chunk = 1000000
    fileprivate let buffer = 100000
    
    fileprivate var materialIndex = 0
    //private var normalArray = [SCNVector3]()
    
    fileprivate var version: String! = ""
    fileprivate var format: String! = ""
    fileprivate var floatSize: String! = ""
    
    // raw data
    fileprivate var rawVertexArray = [SCNVector3]()
    fileprivate var rawNormalArray = [SCNVector3]()
    fileprivate var rawSortedNormalArray = [SCNVector3]()
    fileprivate var rawTexcoordArray = [[Float32]]()
    fileprivate var rawVertexIndexArray = [[Int]]()
    fileprivate var rawNormalIndexArray = [[Int]]()
    fileprivate var rawMaterialIndexArray = [Int]()

    fileprivate var materialArray = [SCNMaterial]()

    // vertexIndex => normalIndex
    fileprivate var normalMap = [Int: Int]()
    
    // vertexIndex => normalIndex => vertexIndex
    fileprivate var vertexNormalMap = [Int: [Int: Int]]()

    // vertex data
    fileprivate var vertexCount = 0
    fileprivate var vertexArray = [Float32]()
    fileprivate var normalArray = [Float32]()
    fileprivate var texcoordArray = [Float32]()

    // index data
    fileprivate var indexCount = 0
    fileprivate var indexArray = [[Int32]]()
    
    // geometry data
    fileprivate var elementArray: [SCNGeometryElement]! = nil
    
    //internal var directoryPath: String! = ""
    //internal var binaryData: Data! = nil
    //internal var length = 0
    
    internal override init(data: Data!, directoryPath: String! = "") {
        super.init(data: data, directoryPath: directoryPath)
        //self.directoryPath = directoryPath
        //self.binaryData = data
        self.offset = 0
        
        let nsString = NSString(data: self.binaryData, encoding: String.Encoding.shiftJIS.rawValue)
        self.length = nsString!.length
        self.text = nsString as! String
        
        self.subText = self.text
        /*
        self.subText = self.text.substringWithRange(
            Range(
                start: self.text.startIndex,
                end: self.text.startIndex.advancedBy(self.maxChunkLength)
            )
        )

        print("--------------------- subText changed ---------------------------")
        print(self.subText)
        print("-----------------------------------------------------------------")
        */
    }
    
    /**
     */
    static func getNode(_ data: Data, directoryPath: String! = "") -> MMDNode? {
        let reader = MMDXReader(data: data, directoryPath: directoryPath)
        let node = reader.loadXFile()
        
        return node
    }
    
    // MARK: - Loading X File
    fileprivate func loadXFile() -> MMDNode? {
        // initialize working variables
        self.workingNode = MMDNode()
        
        if !self.XFileHeader() {
            print("header format error")
            self.err = 1
            return nil
        }
        
        var end = false
        while(!end) {
            let result = self.XObjectLong()
            
            if result == nil {
                end = true
            }
            if let check = result as? Bool {
                end = !check
            }
        }
        
        if self.err != 0 {
            print("xobj format error: \(self.err)")
            return nil
        }
        self.splitFaceNormals()

        self.workingGeometry = self.createGeometry()
        self.workingGeometryNode = SCNNode(geometry: self.workingGeometry)
        self.workingGeometryNode.name = "Geometry"
        self.workingGeometryNode.castsShadow = true
        
        self.workingNode.addChildNode(self.workingGeometryNode)
        self.workingNode.castsShadow = true
        
        self.workingNode.categoryBitMask = 0x02 // debug
        
        return self.workingNode
    }
    
    /**
        move start position of text
        - parameter len: string length to move
     */
    fileprivate func moveIndex(_ len: Int) {
        self.offset += len
    }
    
    /*
    private func moveIndex(len: Int) {
        //self.text = self.text.substringFromIndex( self.text.startIndex.advancedBy(len) )
        self.offset += len
        //self.subText = self.text.substringFromIndex( self.text.startIndex.advancedBy(self.offset) )
        
        //if (self.offset > self.chunk) {
        /*
        self.totalOffset += chunk
        self.subText = self.text.substringFromIndex( self.text.startIndex.advancedBy(self.totalOffset) )
        self.offset -= chunk
        print("totalOffset: \(totalOffset), offset: \(offset)")
        */
        //self.getStringChunk(self.chunk)
        //}
    }
    */
    
    /*
    private let minChunkLength = 50
    private let maxChunkLength = 200
    private var chunkStartPos = 0
    private var chunkEndPos = 200
    private var totalOffset = 0
    private func moveIndex(len: Int) {
        self.offset += len
        //self.subText = self.text.substringFromIndex( self.text.startIndex.advancedBy(self.offset) )
        
        if self.offset + self.minChunkLength > self.chunkEndPos {
            if self.chunkEndPos != self.length {
                self.chunkStartPos = self.offset
                self.chunkEndPos = self.offset + self.maxChunkLength
                
                if self.chunkEndPos > self.length {
                    self.chunkEndPos = self.length
                }
                self.subText = self.text.substringWithRange(
                    Range(
                        start: self.text.startIndex.advancedBy(self.chunkStartPos),
                        end: self.text.startIndex.advancedBy(self.chunkEndPos)
                    )
                )
                print("--------------------- subText changed ---------------------------")
                print(self.subText)
                print("-----------------------------------------------------------------")
            }
        }
        //if (self.offset > self.chunk) {
        /*
        self.totalOffset += chunk
        self.subText = self.text.substringFromIndex( self.text.startIndex.advancedBy(self.totalOffset) )
        self.offset -= chunk
        print("totalOffset: \(totalOffset), offset: \(offset)")
        */
        //self.getStringChunk(self.chunk)
        //}
    }
     */
    
    fileprivate func getMatches(_ pattern: Regexp!) -> [String]? {
        self.skip()
        
        let str = pattern.matches(self.subText, startIndex: self.offset)
        //let str = pattern.matches(self.subText, startIndex: self.offset - chunkStartPos)
        
        if let matches = str as [String]! {
            self.moveIndex((matches[0] as NSString).length)
            
            return matches
        }
        
        return nil
    }
    
    /**
        get strings whitch match a given pattern and move index
        - parameter: regexp pattern
        - returns: string
    */
    fileprivate func getString(_ pattern: Regexp!) -> String? {
        let matches = self.getMatches(pattern)
        
        if matches == nil {
            return nil
        }
        
        return matches![0]
    }

    /**
        skip space, tab
    */
    /*
    private func skip() {
        let nsString = self.subText as NSString
        var i = 0
        var code = nsString.characterAtIndex(0)
        var oldCode = code
        var ignoreChars = 0
        
        //  9: Horizontal Tab
        // 10: Line Feed
        // 11: Vertical Tab
        // 12: New Page
        // 13: Carriage Return
        // 32: Space
        while code == 32 || (9 <= code && code <= 13) {
            i++
            code = nsString.characterAtIndex(i)
            
            if oldCode == 13 && code == 10 {
                // treat CR+LF as 1 character
                ignoreChars++
            }
            
            oldCode = code
        }

        if i > 0 {
            self.moveIndex(i - ignoreChars)
        }
    }
     */
    fileprivate func skip() {
        let str = skipPattern.matches(self.subText, startIndex: self.offset)
        
        if let matches = str as [String]! {
            self.moveIndex((matches[0] as NSString).length)
        }
    }
    let skipPattern = Regexp("^\\s+")
    
    let integerPattern = Regexp("^((-|\\+)?\\d+);?")
    /**
        get Int value
        - returns: Int value
    */
    fileprivate func getInt() -> Int? {
        let str = self.getMatches(integerPattern)

        if str == nil {
            return nil
        }
        
        let val = Int(str![1])

        return val
    }
    
    /**
     get Int32 value
     - returns: Int32 value
     */
    fileprivate func getInt32() -> Int32? {
        let str = self.getMatches(integerPattern)
        
        if str == nil {
            return nil
        }
        
        let val = Int32(str![1])
        
        return val
    }

    let floatPattern = Regexp("^((-|\\+)?(\\d)*\\.(\\d)*);?")
    /**
        get Float value
        - returns: Float value
    */
    fileprivate func getFloat() -> Float? {
        let str = self.getMatches(floatPattern)
        
        if str == nil {
            return nil
        }
        
        let val = Float(str![1])
        
        return val
    }

    /**
     get CGFloat value
     - returns: CGFloat value
     */
    fileprivate func getCGFloat() -> CGFloat? {
        let str = self.getMatches(floatPattern)
        
        if str == nil {
            return nil
        }
        
        let val = CGFloat(Float(str![1])!)
        
        return val
    }

    /**
     get Float32 value
     - returns: Float32 value
     */
    fileprivate func getFloat32() -> Float32? {
        let str = self.getMatches(floatPattern)
        
        if str == nil {
            return nil
        }
        
        let val = Float32(str![1])
        
        return val
    }

    fileprivate func getOSFloat() -> OSFloat? {
        return OSFloat(self.getFloat()!)
    }

    let commaOrSemicolonPattern = Regexp("^[,;]")
    /**
        skip "," or ";"
    */
    fileprivate func getCommaOrSemicolon() {
        /*
        let nsString = self.subText as NSString
        let code = nsString.characterAtIndex(0)
        
        if code == 44 || code == 59 {
            self.moveIndex(1)
        }
        */
        self.getMatches(commaOrSemicolonPattern)
    }

    let wordPattern = Regexp("^\\w+")
    /**
        get string value
        - returns: word
    */
    fileprivate func getWord() -> String? {
        return self.getString(wordPattern)
    }

    let uuidPattern = Regexp("^<[\\w-]+>")
    /**
        get UUID
        - returns: UUID string
    */
    fileprivate func getUUID() -> String? {
        return self.getString(uuidPattern)
    }
    
    let leftBracePattern = Regexp("^\\{")
    /**
        get "{"
        - returns: "{" if it matches. nil if it doesn't match
    */
    fileprivate func getLeftBrace() -> String? {
        return self.getString(leftBracePattern)
    }
    
    let rightBracePattern = Regexp("^\\}")
    /**
        get "}"
        - returns: "}" if it matches. nil if it doesn't match
    */
    fileprivate func getRightBrace() -> String? {
        return self.getString(rightBracePattern)
    }
    
    let memberPattern = Regexp("^((array\\s+\\w+\\s+\\w+\\[(\\d+|\\w+)\\]|\\w+\\s+\\w+)\\s*;|\\[[\\w.]+\\])")
    /**
        get member string
        - returns: member string
    */
    fileprivate func getMember() -> String? {
        return self.getString(memberPattern)
    }

    let filenamePattern = Regexp("^\"(.*)\";?")
    /**
        get filename string
        - returns: file name
    */
    fileprivate func getFilename() -> String? {
        let str = self.getMatches(filenamePattern)
        
        if str == nil {
            return nil
        }

        return str![1]
    }
    
    /**
        get integer array
        - returns: integer array
    */
    fileprivate func getIntArray() -> [Int]? {
        let n = self.getInt()!
        var arr = [Int]()
        
        for _ in 0..<n {
            arr.append(getInt()!)
            self.getCommaOrSemicolon()
        }
        
        return arr
    }
    
    /**
        get Int32 array
        - returns: Int32 array
     */
    fileprivate func getInt32Array() -> [Int32]? {
        let n = self.getInt()!
        var arr = [Int32]()
        
        for _ in 0..<n {
            arr.append(getInt32()!)
            self.getCommaOrSemicolon()
        }
        
        return arr
    }

    /**
        get float array
        - returns: float array
    */
    fileprivate func getFloatArray() -> [Float]? {
        let n = self.getInt()!
        var arr = [Float]()
        
        for _ in 0..<n {
            arr.append(self.getFloat()!)
            self.getCommaOrSemicolon()
        }
        
        return arr
    }

    /**
        get Vector3 value
        - parameter invertZSign: if it's true, invert z sign (+/-)
        - returns: SCNVector3 value
    */
    fileprivate func getVector3(_ invertZSign: Bool = false) -> SCNVector3 {
        var v = SCNVector3()
        v.x = self.getOSFloat()!
        v.y = self.getOSFloat()!
        v.z = self.getOSFloat()!
        
        if invertZSign {
            v.z = -v.z
        }

        self.getCommaOrSemicolon()
        
        return v
    }

    /**
        get Vector4 value
        - returns: SCNVector4 value
    */
    fileprivate func getVector4() -> SCNVector4 {
        var v = SCNVector4()
        v.x = self.getOSFloat()!
        v.y = self.getOSFloat()!
        v.z = self.getOSFloat()!
        v.w = self.getOSFloat()!

        self.getCommaOrSemicolon()
        
        return v
    }
    

    /**
        calculate normal vector from 3 vertices
    */
    fileprivate func calcNormal(_ v1: SCNVector3, _ v2: SCNVector3, _ v3: SCNVector3) -> SCNVector3 {
        let ax = v3.x - v1.x
        let ay = v3.y - v1.y
        let az = v3.z - v1.z
        let bx = v2.x - v1.x
        let by = v2.y - v1.y
        let bz = v2.z - v1.z

        let x = ay * bz - az * by
        let y = az * bx - ax * bz
        let z = ax * by - ay * bx
        
        let x2 = x * x
        let y2 = y * y
        let z2 = z * z
        let r = 1.0 / sqrt(x2 + y2 + z2)

        let rx = r * x
        let ry = r * y
        let rz = r * z

        let normal = SCNVector3Make(OSFloat(rx), OSFloat(ry), OSFloat(rz))
        
        return normal
    }
    
    /*
    private func getVertexAtIndex(index: Int) -> SCNVector3! {
        let x = self.vertexArray[index * 3 + 0]
        let y = self.vertexArray[index * 3 + 1]
        let z = self.vertexArray[index * 3 + 2]

        let vector = SCNVector3Make(OSFloat(x), OSFloat(y), OSFloat(z))
        
        return vector
    }
    
    private func getNormalAtIndex(index: Int) -> SCNVector3! {
        let x = self.normalArray[index * 3 + 0]
        let y = self.normalArray[index * 3 + 1]
        let z = self.normalArray[index * 3 + 2]
        
        let vector = SCNVector3Make(OSFloat(x), OSFloat(y), OSFloat(z))

        return vector
    }
    */

    /*
    private func copyVertexData(index: Int, normal: SCNVector3) {
        self.vertexArray.append(self.vertexArray[index * 3 + 0])
        self.vertexArray.append(self.vertexArray[index * 3 + 1])
        self.vertexArray.append(self.vertexArray[index * 3 + 2])

        self.normalArray.append(Float32(normal.x))
        self.normalArray.append(Float32(normal.y))
        self.normalArray.append(Float32(normal.z))

        self.texcoordArray.append(self.texcoordArray[index * 2 + 0])
        self.texcoordArray.append(self.texcoordArray[index * 2 + 1])
        
        self.materialIndexArray.append(self.materialIndexArray[index])
    }
    */
    
    
    /**
        1. flatten vertexIndexArray and normalIndexArray
        2. copy vertex/normal/texcoord if different normals refer the same vertex
    */
    fileprivate func splitFaceNormals() {
        let numFaces = self.rawVertexIndexArray.count

        print("rawTexcoordArray.count = \(self.rawTexcoordArray.count)")
        // set texcoord
        if self.rawTexcoordArray.count == 0 {
            let float32Pairs = [Float32](repeating: 0.0, count: 2)
            
            for _ in 0..<numFaces {
                self.rawTexcoordArray.append(float32Pairs)
            }
        }
        
        // create normal
        if self.rawNormalArray.count == 0 {
            for i in 0..<numFaces {
                let vertexIndex = self.rawVertexIndexArray[i]
                let angles = vertexIndex.count
                
                // FIXME: calc proper normal
                let normal = calcNormal(
                    self.rawVertexArray[vertexIndex[0]],
                    self.rawVertexArray[vertexIndex[1]],
                    self.rawVertexArray[vertexIndex[angles-1]]
                )
                
                self.rawNormalArray.insert(normal, at: i)

                let normalIndex = [Int](repeating: i, count: angles)
                self.rawNormalIndexArray.insert(normalIndex, at: i)
            }
        }
        
        // flatten arrays
        var flatVertexIndexArray = [Int]()
        var flatNormalIndexArray = [Int]()
        var flatMaterialIndexArray = [Int]()
        
        
        self.vertexCount = 0
        self.indexCount = 0

        for i in 0..<numFaces {
            let vertexIndex = self.rawVertexIndexArray[i]
            let normalIndex = self.rawNormalIndexArray[i]
            let materialIndex = self.rawMaterialIndexArray[i]
            
            let angles = vertexIndex.count

            for j in 2..<angles {
                flatVertexIndexArray.append(vertexIndex[0])
                flatVertexIndexArray.append(vertexIndex[j])
                flatVertexIndexArray.append(vertexIndex[j-1])
                
                flatNormalIndexArray.append(normalIndex[0])
                flatNormalIndexArray.append(normalIndex[j])
                flatNormalIndexArray.append(normalIndex[j-1])
                
                flatMaterialIndexArray.append(materialIndex)
                flatMaterialIndexArray.append(materialIndex)
                flatMaterialIndexArray.append(materialIndex)
                
                self.indexCount += 1
            }
        }
        
        // make map of vertex to normal
        var vertexCount = self.rawVertexArray.count
        //let zeroVector3 = SCNVector3Make(0, 0, 0)
        
        let flatArrayCount = flatVertexIndexArray.count
        for i in 0..<flatArrayCount {
            let vertexIndex = flatVertexIndexArray[i]
            let normalIndex = flatNormalIndexArray[i]
            let materialIndex = flatMaterialIndexArray[i]
            
            let vertexToNormal = self.vertexNormalMap[vertexIndex]
            let newVertexIndex = vertexToNormal?[normalIndex]
            
            if vertexToNormal == nil {
                // new
                self.vertexNormalMap[vertexIndex] = [Int:Int]()
                self.vertexNormalMap[vertexIndex]![normalIndex] = vertexIndex
                
                self.normalMap[vertexIndex] = normalIndex
            }else if newVertexIndex == nil {
                // conflict; add vertex data at index(vertexCount)
                self.rawVertexArray.append( self.rawVertexArray[vertexIndex] )
                self.rawTexcoordArray.append( self.rawTexcoordArray[vertexIndex] )
                
                self.vertexNormalMap[vertexIndex]![normalIndex] = vertexCount
                self.normalMap[vertexCount] = normalIndex
                
                flatVertexIndexArray[i] = vertexCount
                
                vertexCount += 1
            }else{
                // reuse
                flatVertexIndexArray[i] = newVertexIndex!
            }
        }

        // create normal data
        for i in 0..<vertexCount {
            var normalIndex = self.normalMap[i]
            
            if normalIndex == nil {
                normalIndex = 0
            }
            
            self.rawSortedNormalArray.append( self.rawNormalArray[normalIndex!] )
        }

        // create vertex data
        self.vertexCount = self.rawVertexArray.count
        self.vertexArray = [Float32]()
        for i in 0..<self.vertexCount {
            self.vertexArray.append( Float32(self.rawVertexArray[i].x) )
            self.vertexArray.append( Float32(self.rawVertexArray[i].y) )
            self.vertexArray.append( Float32(self.rawVertexArray[i].z) )
        }
        
        self.normalArray = [Float32]()
        for i in 0..<self.vertexCount {
            self.normalArray.append( Float32(self.rawSortedNormalArray[i].x) )
            self.normalArray.append( Float32(self.rawSortedNormalArray[i].y) )
            self.normalArray.append( Float32(self.rawSortedNormalArray[i].z) )
        }
        
        self.texcoordArray = [Float32]()
        for i in 0..<self.rawTexcoordArray.count {
            self.texcoordArray.append( self.rawTexcoordArray[i][0] )
            self.texcoordArray.append( self.rawTexcoordArray[i][1] )
        }

        // create index data
        self.indexArray = [[Int32]]()
        for _ in 0..<self.materialArray.count {
            self.indexArray.append( [Int32]() )
        }

        for i in 0..<flatMaterialIndexArray.count {
            let materialIndex = flatMaterialIndexArray[i]
            let vertexIndex = flatVertexIndexArray[i]
            
            self.indexArray[materialIndex].append( Int32(vertexIndex) )
        }
    }
    
    fileprivate func createGeometry() -> SCNGeometry {
        //let vertexData = Data(bytes: UnsafePointer<UInt8>(self.vertexArray), count: 4 * 3 * self.vertexCount)
        
        //let vertexData = NSData(bytes: UnsafePointer<UInt8>(self.vertexArray), length: 4 * 3 * self.vertexCount)
        let vertexData = NSData(bytes: self.vertexArray, length: 4 * 3 * self.vertexCount)
        //let normalData = Data(bytes: UnsafePointer<UInt8>(self.normalArray), count: 4 * 3 * self.vertexCount)
        let normalData = NSData(bytes: self.normalArray, length: 4 * 3 * self.vertexCount)
        //let texcoordData = Data(bytes: UnsafePointer<UInt8>(self.texcoordArray), count: 4 * 2 * self.vertexCount)
        let texcoordData = NSData(bytes: self.texcoordArray, length: 4 * 2 * self.vertexCount)
        
        // FIXME: implement bones
        //let boneIndicesData = NSData(bytes: self.boneIndicesArray, length: 2 * 2 * self.vertexCount)
        //let boneWeightsData = NSData(bytes: self.boneWeightsArray, length: 4 * 2 * self.vertexCount)
        //let edgeData = NSData(bytes: self.edgeArray, length: 1 * 1 * self.vertexCount)
        //let indexData = NSData(bytes: self.indexArray, length: 2 * self.indexCount)
        
        //let vertexSource = SCNGeometrySource(data: vertexData, semantic: SCNGeometrySourceSemanticVertex, vectorCount: Int(self.vertexCount), floatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        let vertexSource = SCNGeometrySource(data: vertexData as Data, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: Int(self.vertexCount), usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        let normalSource = SCNGeometrySource(data: normalData as Data, semantic: SCNGeometrySource.Semantic.normal, vectorCount: Int(self.vertexCount), usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        let texcoordSource = SCNGeometrySource(data: texcoordData as Data, semantic: SCNGeometrySource.Semantic.texcoord, vectorCount: Int(self.vertexCount), usesFloatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        //let boneIndicesSource = SCNGeometrySource(data: boneIndicesData, semantic: SCNGeometrySourceSemanticBoneIndices, vectorCount: Int(vertexCount), floatComponents: false, componentsPerVector: 2, bytesPerComponent: 2, dataOffset: 0, dataStride: 4)
        //let boneWeightsSource = SCNGeometrySource(data: boneWeightsData, semantic: SCNGeometrySourceSemanticBoneWeights, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        
        self.elementArray = [SCNGeometryElement]()
        var newMaterialArray = [SCNMaterial]()
        for materialNo in 0..<self.materialArray.count {
            let indexArray = self.indexArray[materialNo]
            let indexCount = indexArray.count / 3
            
            if indexCount > 0 {
                //let indexData = Data(bytes: UnsafePointer<UInt8>(indexArray), count: 4 * 3 * indexCount)
                let indexData = NSData(bytes: indexArray, length: 4 * 3 * indexCount)
                var indices = [Int32]()
            
                let element = SCNGeometryElement(data: indexData as Data, primitiveType: .triangles, primitiveCount: indexCount, bytesPerIndex: 4)
            
                self.elementArray.append(element)
                newMaterialArray.append(self.materialArray[materialNo])
            }
        }
        
        let geometry = SCNGeometry(sources: [vertexSource, normalSource, texcoordSource], elements: self.elementArray)
        geometry.materials = newMaterialArray
        geometry.name = "Geometry"
        
        return geometry
    }

    
    
    let headerPattern = Regexp("^xof (\\d\\d\\d\\d)([ \\w][ \\w][ \\w][ \\w])(\\d\\d\\d\\d)")
    /**
        check header format
        - returns: true if right header format
    */
    fileprivate func XFileHeader() -> Bool {
        //let matches = self.headerPattern.matches(self.subText, startIndex: self.offset)
        let matches = self.getMatches(headerPattern)
        if matches == nil {
            return false
        }
        
        //moveIndex(16)
        
        self.version = matches![1]
        self.format = matches![2]
        self.floatSize = matches![3]
        
        return true
    }
    
    /**
        read Object value
        - returns: XObject
    */
    fileprivate func XObjectLong() -> AnyObject? {
        let id = self.getWord()
        
        if id == nil {
            return nil
        }
        
        print("************* id: \(id) ******************")

        switch(id!) {
        case "template":
            return self.Template() as AnyObject?
        case "Header":
            return self.Header() as AnyObject?
        case "Mesh":
            return self.Mesh() as AnyObject?
        case "MeshMaterialList":
            return self.MeshMaterialList() as AnyObject?
        case "MeshNormals":
            return self.MeshNormals() as AnyObject?
        case "MeshTextureCoords":
            return self.MeshTextureCoords() as AnyObject?
        case "MeshVertexColors":
            return self.MeshVertexColors() as AnyObject?
        default:
            print("unknown type: \(id)")
        }
        return nil
    }


#if os(iOS) || os(tvOS) || os(watchOS)
    /**
        read ColorRGB value
        - returns: ColorRGBA object. Alpha is 1.0
     */
    fileprivate func ColorRGB() -> UIColor {
        let r = self.getOSFloat()!
        let g = self.getOSFloat()!
        let b = self.getOSFloat()!
        let a = Float(1.0)
        
        self.getCommaOrSemicolon()
        
        return UIColor(colorLiteralRed: r, green: g, blue: b, alpha: a)
    }

    /**
        read ColorRGBA value
        - returns: ColorRGBA object
     */
    fileprivate func ColorRGBA() -> UIColor {
        let r = self.getOSFloat()!
        let g = self.getOSFloat()!
        let b = self.getOSFloat()!
        let a = self.getOSFloat()!
        
        self.getCommaOrSemicolon()
        
        return UIColor(colorLiteralRed: r, green: g, blue: b, alpha: a)
    }
    
    fileprivate func IndexedColor() -> UIColor {
        let index: Int? = self.getInt()
        let color = self.ColorRGBA()
        // color.index = index
        
        return color
    }

#elseif os(macOS)
    /**
        read ColorRGB value
        - returns: ColorRGBA object. Alpha is 1.0
    */
    private func ColorRGB() -> NSColor {
        let r = self.getOSFloat()!
        let g = self.getOSFloat()!
        let b = self.getOSFloat()!
        let a = CGFloat(1.0)
    
        self.getCommaOrSemicolon()

        return NSColor(red: r, green: g, blue: b, alpha: a)
    }

    /**
        read ColorRGBA value
        - returns: ColorRGBA object
    */
    private func ColorRGBA() -> NSColor {
        let r = self.getOSFloat()!
        let g = self.getOSFloat()!
        let b = self.getOSFloat()!
        let a = self.getOSFloat()!
    
        self.getCommaOrSemicolon()
    
        return NSColor(red: r, green: g, blue: b, alpha: a)
    }
    
    private func IndexedColor() -> NSColor {
        let index: Int? = self.getInt()
        let color = self.ColorRGBA()
        // color.index = index
    
        return color
    }

#endif

    /**
        read Coords2d object
        - returns: texture coord
    */
    fileprivate func Coords2d() -> [Float32] {
        var v = [Float32]()
        
        v.append(self.getFloat32()!)
        v.append(self.getFloat32()!)
        self.getCommaOrSemicolon()
        
        return v
    }

    fileprivate func Template() -> Bool {
        let name = self.getWord()

        self.getLeftBrace()
        let uuid = self.getUUID()

        var member: String? = nil
        repeat {
            member = self.getMember()
        }while(member != nil)
        self.getRightBrace()
        
        return true
    }
    
    fileprivate func Header() -> Bool {
        self.getLeftBrace()
        
        let major: Int? = self.getInt()
        let minor: Int? = self.getInt()
        let flags: Int? = self.getInt()
        
        self.getRightBrace()
        
        return true
    }
    
    fileprivate func Material() -> SCNMaterial {
        let material = SCNMaterial()
        
        self.getLeftBrace()
        
        material.diffuse.contents = self.ColorRGBA()
        material.ambient.contents = material.diffuse.contents
        material.shininess = CGFloat(self.getFloat()!)
        material.specular.contents = self.ColorRGB()
        material.emission.contents = self.ColorRGB()
        
        let name = self.getWord()
        if name == "TextureFilename" {
            let textureFilePath = self.TextureFilename()
            if textureFilePath != nil {
                #if os(iOS) || os(tvOS) || os(watchOS)
                    let black = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0)
                    let image = UIImage(contentsOfFile: textureFilePath!)
                #elseif os(macOS)
                    let black = NSColor(red: 0, green: 0, blue: 0, alpha: 0)
                    let image = NSImage(contentsOfFile: textureFilePath!)
                #endif
                
                if image != nil {
                    //material.ambient.contents = black
                    material.emission.contents = self.createTexture(image!, light: material.emission.contents as! OSColor)
                    material.emission.wrapS = .repeat
                    material.emission.wrapT = .repeat
                    material.diffuse.contents = self.createTexture(image!, light: material.diffuse.contents as! OSColor)
                    material.diffuse.wrapS = .repeat
                    material.diffuse.wrapT = .repeat
                }
            }
        }

        self.getRightBrace()
        
        return material
    }

    fileprivate func Mesh() -> Bool {
        self.getLeftBrace()
        
        // vertices
        let rawVertexCount = self.getInt()!
        print("vertexCount: \(rawVertexCount)")
        
        for _ in 0..<rawVertexCount {
            let pos = self.getVector3(true)
            
            self.rawVertexArray.append(pos)
            
            self.getCommaOrSemicolon()
        }
        
        // faces
        self.indexCount = 0
        let nFaces = self.getInt()!
        print("num faces: \(nFaces)")
        
        for _ in 0..<nFaces {
            let face = self.getIntArray()!
            
            self.rawVertexIndexArray.append(face)
        }
        
        self.getRightBrace()
        
        return true
    }
    
    fileprivate func MeshMaterialList() -> Bool {
        self.getLeftBrace()
        
        // materials
        let nMaterials = self.getInt()!
        print("materials: \(nMaterials)")
        
        // face materials
        let nFaceIndices = self.getInt()!
        print("face indices: \(nFaceIndices)")

        for _ in 0..<nFaceIndices {
            let materialNo = self.getInt()!
            self.getCommaOrSemicolon()
            
            self.rawMaterialIndexArray.append(materialNo)
        }
        
        // materials
        var name: String? = self.getWord()
        
        while name == "Material" {
            let material = self.Material()
            
            self.materialArray.append(material)
            
            name = self.getWord()
        }
        
        self.getRightBrace()
        
        return true
    }
    
    fileprivate func MeshNormals() -> Bool {
        self.getLeftBrace()
        
        let nNormals = self.getInt()!
        print("mesh normals: \(nNormals)")
        
        for _ in 0..<nNormals {
            let normal = self.getVector3(true)
            
            self.rawNormalArray.append(normal)
        }
        
        let nFaceNormals = self.getInt()!
        print("normal indices: \(nFaceNormals)")
        
        for faceNo in 0..<nFaceNormals {
            let faceNormals = self.getIntArray()!
            
            self.rawNormalIndexArray.append(faceNormals)
        }
        
        self.getRightBrace()
        
        return true
    }
    
    fileprivate func MeshTextureCoords() -> Bool {
        self.getLeftBrace()
        
        // suppose to be the same number as vertexCount
        let nTextureCoords = self.getInt()!
        print("textureCoords: \(nTextureCoords)")
        
        for _ in 0..<nTextureCoords {
            let texcoord = self.Coords2d()
            
            self.rawTexcoordArray.append(texcoord)
        }
        
        self.getRightBrace()
        
        return true
    }
    
    fileprivate func MeshVertexColors() -> Bool {
        self.getLeftBrace()
        
        let nVertexColors = self.getInt()!
        for _ in 0..<nVertexColors {
            let v = self.IndexedColor()
            // FIXME: not implemented.
        }
        
        self.getRightBrace()
        
        return true
    }
    
    fileprivate func TextureFilename() -> String? {
        self.getLeftBrace()
        
        let name = self.getFilename()
        var filePath = name!.replacingOccurrences(of: "\\\\", with: "/")
        
        print("before: \(name), after: \(filePath)")
        
        filePath = (self.directoryPath as NSString).appendingPathComponent(filePath)
        
        print("filePath: \(filePath)")
        
        self.getRightBrace()
        
        return filePath
    }
}
