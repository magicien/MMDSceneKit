//
//  MMDNode.swift
//  MMDSceneKit
//
//  Created by magicien on 12/9/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

public enum MMDNodeType {
    case ROTATE
    case ROTATE_TRANSLATE
    case IK
    case UNKNOWN
    case IK_CHILD
    case ROTATE_CHILD
    case IK_TARGET
    case HIDDEN
    case TWIST
    case ROLL
}

public class MMDFloat: NSObject {
    public var value: Float = 0.0
}

public class MMDNode: SCNNode, SCNProgramDelegate {
    public internal(set) var physicsBehaviors: [SCNPhysicsBehavior]! = []
    public internal(set) var type: MMDNodeType = .UNKNOWN
    // FIXME: internal variant
    public var ikTargetBone: MMDNode? = nil
    //public var ikConstraint: SCNIKConstraint? = nil
    internal var ikConstraint: MMDIKConstraint? = nil
    
    // FIXME: use morpher
    public var vertexCount = 0
    public var vertexArray: [Float32]! = nil
    public var normalArray: [Float32]! = nil
    public var texcoordArray: [Float32]! = nil
    public var boneIndicesArray: [UInt16]! = nil
    public var boneWeightsArray: [Float32]! = nil
    public var indexCount = 0
    public var indexArray: [UInt16]! = nil
    public var materialCount = 0
    public var materialArray: [SCNMaterial]! = nil
    public var materialIndexCountArray: [Int]! = nil
    public var elementArray: [SCNGeometryElement]? = nil
    public var boneArray: [MMDNode]! = nil
    public var boneInverseMatrixArray: [NSValue]! = nil
    public var rootBone: MMDNode! = nil
    
    // FIXME: use morpher
    public var faceIndexArray: [Int]? = nil
    public var faceDataArray: [[Float32]]? = nil
    public var faceWeights: [MMDFloat]! = nil
    public var geometryMorpher: SCNMorpher! = nil

    private let faceWeightsPattern = Regexp("faceWeights\\[(\\d+)\\]")
    
    // FIXME: use morpher
    public func updateFace() {
        if self.faceDataArray == nil {
            return
        }

        // set base face
        let baseFace = self.faceDataArray![0]
        for i in 0..<self.faceIndexArray!.count {
            let index = self.faceIndexArray![i]
            self.vertexArray![index] = baseFace[i]
        }
        
        for faceNo in 1..<self.faceDataArray!.count {
            let faceData = self.faceDataArray![faceNo]
            let weight = self.faceWeights[faceNo].value
            print("weight[\(faceNo)]: \(weight)")
            if weight > 0 {
                for i in 0..<self.faceIndexArray!.count {
                    let index = self.faceIndexArray![i]
                    self.vertexArray![index] += faceData[i] * weight
                }
            }
        }
        
        /*
        let geometryNode = self.childNodeWithName("Geometry", recursively: true)
        let targetCount = geometryNode!.presentationNode.morpher!.targets.count
        print("targetCount: \(targetCount)")
        for faceNo in 0..<targetCount {
            let weight = geometryNode!.presentationNode.morpher!.weightForTargetAtIndex(faceNo)
            if weight > 0 {
                let faceData = self.faceDataArray![faceNo]
                print("weight[\(faceNo)]: \(weight)")
                for i in 0..<self.faceIndexArray!.count {
                    let index = self.faceIndexArray![i]
                    self.vertexArray![index] += faceData[i] * Float32(weight)
                }
            }
        }
        */

        //self.updateVertexData()
    }
    
    public func updateVertexData() {
        let vertexData = NSData(bytes: self.vertexArray, length: 4 * 3 * self.vertexCount)
        let normalData = NSData(bytes: self.normalArray, length: 4 * 3 * self.vertexCount)
        let texcoordData = NSData(bytes: self.texcoordArray, length: 4 * 2 * self.vertexCount)
        let boneIndicesData = NSData(bytes: self.boneIndicesArray, length: 2 * 2 * self.vertexCount)
        let boneWeightsData = NSData(bytes: self.boneWeightsArray, length: 4 * 2 * self.vertexCount)
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
            
            elementArray.append(element)
            
            indexPos += length
        }
        
        let geometry = SCNGeometry(sources: [vertexSource, normalSource, texcoordSource], elements: elementArray)
        geometry.materials = self.materialArray
        geometry.name = "Geometry"
        
        let newGeometryNode = SCNNode(geometry: geometry)
        newGeometryNode.name = "Geometry"
        
        let skinner = SCNSkinner(baseGeometry: geometry, bones: self.boneArray, boneInverseBindTransforms: self.boneInverseMatrixArray, boneWeights: boneWeightsSource, boneIndices: boneIndicesSource)
        
        newGeometryNode.skinner = skinner
        newGeometryNode.skinner!.skeleton = self.rootBone
        newGeometryNode.morpher = self.geometryMorpher
        
        let oldGeometryNode = self.childNodeWithName("Geometry", recursively: true)
        self.replaceChildNode(oldGeometryNode!, with: newGeometryNode)
    }
    
    
    /*
    public func updateVertexData() {
        let geometryNode = self.childNodeWithName("Geometry", recursively: true)

        let vertexCount = self.vertexArray!.count / 3
        let vertexData = NSData(bytes: self.vertexArray!, length: 4 * 3 * vertexCount)
        let vertexSource = SCNGeometrySource(data: vertexData, semantic: SCNGeometrySourceSemanticVertex, vectorCount: Int(vertexCount), floatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        
        //let normalSource = geometryNode!.geometry!.geometrySourcesForSemantic(SCNGeometrySourceSemanticNormal).first!
        //let texcoordSource = geometryNode!.geometry!.geometrySourcesForSemantic(SCNGeometrySourceSemanticTexcoord).first!
        //let elementArray = geometryNode!.geometry!.geometryElements
        
        let geometry = SCNGeometry(sources: [vertexSource, self.normalSource!, self.texcoordSource!], elements: self.elementArray!)
        //let geometry = SCNGeometry(sources: [vertexSource, normalSource, texcoordSource], elements: elementArray)
        geometry.materials = geometryNode!.geometry!.materials
        geometry.name = "Geometry"

        let rootBone = self.childNodeWithName("rootBone", recursively: true)
        let newGeometryNode = SCNNode(geometry: geometry)
        newGeometryNode.name = "Geometry"
        
        let skinner = SCNSkinner(baseGeometry: geometry, bones: self.boneArray, boneInverseBindTransforms: self.boneInverseMatrixArray, boneWeights: self.boneWeightsSource!, boneIndices: self.boneIndicesSource!)

        newGeometryNode.skinner = geometryNode!.skinner
        newGeometryNode.skinner!.skeleton = rootBone

        self.replaceChildNode(geometryNode!, with: newGeometryNode)
        //geometryNode!.geometry = geometry
    }
*/
    
    public func program(program: SCNProgram, handleError error: NSError) {
        print("GLSL compile error: \(error)")
    }
    
    
    
    override public func valueForUndefinedKey(key: String) -> AnyObject? {
        if key.hasPrefix("/") {
            let searchKey = (key as NSString).substringFromIndex(1)
            if let node = self.childNodeWithName(searchKey, recursively: true) {
                return node
            }
        } else {
            print("unknown key: \(key)")
            
            let result = self.faceWeightsPattern.matches(key)
            if result != nil {
                let index = Int(result![1])
                let value = self.faceWeights[index!]
                print("match: \(value)")
                return value
            }
        }
        
        return super.valueForUndefinedKey(key)
    }
    
    override public func setValue(value: AnyObject?, forUndefinedKey key: String) {
        print("setValueForUndefinedKey: \(key)")
    }
    
    override public func addAnimation(animation: CAAnimation, forKey key: String?) {
        let geometryNode = self.childNodeWithName("Geometry", recursively: true)
        
        // FIXME: clone values
        if let group = animation as? CAAnimationGroup {
            
            if let animations = group.animations {
                for anim in animations {
                    if let keyAnim = anim as? CAKeyframeAnimation {
                        let boneNameKey = keyAnim.keyPath!.componentsSeparatedByString(".")[0]
                        let boneName = (boneNameKey as NSString).substringFromIndex(1)
                        let bone = self.childNodeWithName(boneName, recursively: true)
                        
                        if boneNameKey == "morpher" {
                            /*
                            if keyAnim.keyPath!.hasPrefix("morpher.weights.") {
                                print("morpher Animation - \(keyAnim.keyPath!)")
                                let faceName = (keyAnim.keyPath! as NSString).substringFromIndex(16)
                                var faceIndex = -1
                                
                                // search face name from geometry node
                                for index in 0..<geometryNode!.morpher!.targets.count {
                                    if geometryNode!.morpher!.targets[index].name == faceName {
                                        faceIndex = index
                                        break
                                    }
                                }

                                if faceIndex >= 0 {
                                    let newKeyPath: String! = "/Geometry.morpher.weights[\(faceIndex)]"
                                    keyAnim.keyPath = newKeyPath
                                    
                                    print("set keyPath: \(keyAnim.keyPath!): \(faceName)")
                                }else{
                                    keyAnim.keyPath = "//"
                                }
                            }
                            */
                            
                            if keyAnim.keyPath!.hasPrefix("morpher.weights.") {
                                print("+++++ morpher Animation - \(keyAnim.keyPath!)")
                                let faceName = (keyAnim.keyPath! as NSString).substringFromIndex(16)
                                var faceIndex = -1
                                
                                // search face name from geometry node
                                for index in 0..<geometryNode!.morpher!.targets.count {
                                    if geometryNode!.morpher!.targets[index].name == faceName {
                                        faceIndex = index
                                        break
                                    }
                                }
                                
                                if faceIndex >= 0 {
                                    //let newKeyPath: String! = "/Geometry.morpher.weights[\(faceIndex)]"
                                    let newKeyPath: String! = "faceWeights[\(faceIndex)].value"
                                    print("Face: \(faceName), KeyPath: \(newKeyPath), duration: \(keyAnim.duration)")
                                    keyAnim.keyPath = newKeyPath

                                    //self.faceWeights[faceIndex] = 1.0
                                    for index in 0..<keyAnim.values!.count {
                                        let val = keyAnim.values![index]
                                        let tim = keyAnim.keyTimes![index]
                                        
                                        print("  \(tim): \(val)")
                                    }
                                }else{
                                    keyAnim.keyPath = "//"
                                }
                            }
                            
                                                    
                        } else if bone != nil {
                            if keyAnim.keyPath!.hasSuffix(".translation.x") {
                                // FIXME: clone values
                            
                                for index in 0..<keyAnim.values!.count {
                                    let origValue = keyAnim.values![index] as! Float
                                    let newValue = origValue + Float(bone!.position.x)
                                    keyAnim.values![index] = newValue
                                }
                            }else if keyAnim.keyPath!.hasSuffix(".translation.y") {
                                for index in 0..<keyAnim.values!.count {
                                    let origValue = keyAnim.values![index] as! Float
                                    let newValue = origValue + Float(bone!.position.y)
                                    keyAnim.values![index] = newValue
                                }
                            }else if keyAnim.keyPath!.hasSuffix(".translation.z") {
                                for index in 0..<keyAnim.values!.count {
                                    let origValue = keyAnim.values![index] as! Float
                                    let newValue = origValue + Float(bone!.position.z)
                                    keyAnim.values![index] = newValue
                                }
                            }
                        }
                    }else{
                    }
                }
            }
        }
        super.addAnimation(animation, forKey: key)
    }    
}
