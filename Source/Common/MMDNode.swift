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

public class DummyNode: NSObject {
    override public func valueForUndefinedKey(key: String) -> AnyObject? {
        print("unknown key: \(key)")
        return self
    }
}

public class MMDNode: SCNNode, SCNProgramDelegate {
    public internal(set) var physicsBehaviors: [SCNPhysicsBehavior]! = []
    public internal(set) var type: MMDNodeType = .UNKNOWN
    public internal(set) var isKnee: Bool = false
    
    // FIXME: internal variant
    public var ikTargetBone: MMDNode? = nil
    //public var ikConstraint: SCNIKConstraint? = nil
    internal var ikConstraint: MMDIKConstraint? = nil
    public var ikArray: [MMDIKConstraint]? = nil

    /*
    public var ikAnim: Float = 0.0 {
        didSet {
            print("ikAnim didSet: \(self.name)")
            self.updateIK()
        }
    }
*/
    
    /*
    private var _ikOn: Bool = false
    public var ikOn: Bool {
        get {
            return self._ikOn
        }
        set(newValue) {
            if !self._ikOn && newValue {
                // start IK
                let ikAction = SCNAction.runBlock() { (node:SCNNode) in
                    print("ikAction: \(self.name!)")
                    //if let mmdNode = node as? MMDNode {
                        // print("  ikAnimValue: \(mmdNode.ikAnim)")
                        //let ikAnimValue = node.valueForKey("ikAnim")
                        //print("  ikAnimValue: \(ikAnimValue)")
                        //mmdNode.updateIK()
                        //mmdNode
                    //}
                    self.updateIK()
                }
                let wait = SCNAction.waitForDuration(1)
                let sequence = SCNAction.sequence([ikAction, wait])
                let repeatAction = SCNAction.repeatActionForever(sequence)
                
                self.runAction(repeatAction, forKey: nil)
            } else if self._ikOn && !newValue {
                // stop IK
                self.removeActionForKey("IKAction")
            }
            self._ikOn = newValue
        }
    }
    */
    
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

    private var dummyNode: DummyNode = DummyNode()
    
    // FIXME: use morpher
    public var faceIndexArray: [Int]? = nil
    public var faceDataArray: [[Float32]]? = nil
    public var faceWeights: [MMDFloat]! = nil
    public var geometryMorpher: SCNMorpher! = nil

    private let faceWeightsPattern = Regexp("faceWeights\\[(\\d+)\\]")
    
    /*
    override public init() {
        super.init()
        
        let ikAnimation = CABasicAnimation(keyPath: "self.ikAnim")
        ikAnimation.fromValue = 0.0
        ikAnimation.toValue = 100.0
        ikAnimation.duration = 1000.0
        ikAnimation.repeatCount = Float.infinity
        ikAnimation.usesSceneTimeBase = false
        self.addAnimation(ikAnimation, forKey: "aaa")
        //self.ikOn = true
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
*/
    
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
            return self.dummyNode
        }
        
        print("unknown key: \(key)")
            
        let result = self.faceWeightsPattern.matches(key)
        if result != nil {
            let index = Int(result![1])
            let value = self.faceWeights[index!]
            print("match: \(value)")
            return value
        }
        
        if key == "kPivotKey" {
            return nil
        }
    
        //return self.dummyNode
        return super.valueForUndefinedKey(key)
    }
    
    override public func setValue(value: AnyObject?, forUndefinedKey key: String) {
        print("setValueForUndefinedKey: \(key)")
    }
    
    override public func addAnimation(animation: CAAnimation, forKey key: String?) {
        let geometryNode = self.childNodeWithName("Geometry", recursively: true)
        
        // FIXME: clone values
        if let group = animation as? CAAnimationGroup {
            let newGroup = group.copy() as! CAAnimationGroup
            newGroup.animations = [CAAnimation]()
            
            if let animations = group.animations {
                for anim in animations {
                    let newAnim = anim.copy()
                    
                    if let keyAnim = newAnim as? CAKeyframeAnimation {
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
                                    //for index in 0..<keyAnim.values!.count {
                                    //    let val = keyAnim.values![index]
                                    //    let tim = keyAnim.keyTimes![index]
                                    //
                                    //    print("  \(tim): \(val)")
                                    //}
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
                    newGroup.animations!.append(newAnim as! CAAnimation)
                }
            }
            super.addAnimation(newGroup, forKey: key)
        }else{
            super.addAnimation(animation, forKey: key)
        }
    }
    
    /**
    update IK bone
    */
    public func updateIK() {
        if self.ikArray == nil {
            return
        }
        
        let zeroThreshold = Float(0.0000001)
        
        for ik in self.ikArray! {
            let ikBone = ik.ikBone
            let targetBone = ik.targetBone
            
            let numBones = ik.boneArray.count
            
            // <update ikBone>
            
            for _ in 0..<ik.iteration {
                boneArrayLoop: for index in 0..<ik.boneArray.count {
                    let bone = ik.boneArray[index]
                    
                    // <update targetBone>
                    // <update bone>
                    let bonePosition = getWorldPosition(bone.presentationNode)
                    let targetPosition = getWorldPosition(targetBone.presentationNode)
                    let ikPosition = getWorldPosition(ikBone.presentationNode)
                    
                    var v1 = sub(bonePosition, targetPosition)
                    var v2 = sub(bonePosition, ikPosition)
                    
                    v1 = normalize(v1)
                    v2 = normalize(v2)
                    
                    var diff = sub(v1, v2)
                    let x2 = diff.x * diff.x
                    let y2 = diff.y * diff.y
                    let z2 = diff.z * diff.z
                    if Float(x2 + y2 + z2) < zeroThreshold {
                        break boneArrayLoop
                    }
                    // MARK: DEBUG
                    let beforeDiffLength = x2 + y2 + z2

                    var v = cross(v1, v2)
                    // worldTransform -> localTransform (rotation)
                    v = inverseCross(v, bone.parentNode!.presentationNode.worldTransform)
                    v = normalize(v)
                    
                    if bone.isKnee {
                        if v.x > 0 {
                            v.x = 1.0
                        } else {
                            v.x = -1.0
                        }
                        v.y = 0
                        v.z = 0
                    }
                    
                    var innerProduct = dot(v1, v2)
                    if innerProduct > 1 {
                        innerProduct = 1
                    } else if innerProduct < -1 {
                        innerProduct = -1
                    }
                    
                    var ikRot = 0.5 * acos(innerProduct)
                    
                    let maxRot = ik.weight * Float(index + 1) * 2
                    if ikRot > maxRot {
                        ikRot = maxRot
                    }
                    
                    let ikSin = OSFloat(sin(ikRot))
                    let ikCos = OSFloat(cos(ikRot))
                    var quat = SCNVector4()
                    
                    // create quaternion
                    quat.x = OSFloat(v.x * ikSin)
                    quat.y = OSFloat(v.y * ikSin)
                    quat.z = OSFloat(v.z * ikSin)
                    quat.w = OSFloat(ikCos)
                    
                    //print("quat: \(quat.x) \(quat.y) \(quat.z) \(quat.w)")

                    if index == ik.boneArray.count-1 {
                        //print("***** before bone *****")
                        //self.printTransform(targetBone)
                        //bone.printWorldTransform()
                        //printWorldTransform(bone.presentationNode)
                        
                        if bone.childNodes.count > 0 {
                            //print("***** before child *****")
                            //printWorldTransform(bone.childNodes[0])
                            //printWorldTransform(bone.childNodes[0].presentationNode)
                            //printWorldPosition(bone.childNodes[0])
                        }
                        
                        //print("")
                        //print("***** target before *****")
                        //printWorldTransform(targetBone.presentationNode)
                    }
                    
                    //rot = cross(quat, bone.rotation)
                    
                    //printRotation(bone.presentationNode)
                    var orgQuat = rotationToQuat(bone.presentationNode.rotation)
                    quat = cross(quat, orgQuat)
                    
                    /*
                    if bone.isKnee {
                        let m23 = 2 * quat.y * quat.z + 2 * quat.w * quat.x
                        let m33 = 1 - 2 * quat.x * quat.x - 2 * quat.y * quat.y
                        
                        if atan2(m23, m33) < 0 {
                            quat.x = -quat.x
                        }
                    }
*/
                    
                    //beforeCheck(bone)
                    
                    bone.rotation = quatToRotation(quat)
                    //printRotation(bone.presentationNode)

                    
                    if bone.isKnee {
                        if bone.eulerAngles.x < 0 {
                            quat.x = -quat.x
                            bone.rotation = quatToRotation(quat)
                            if bone.eulerAngles.x < 0 {
                                //print("***************** ERROR *****************")
                            }
                        }
                    }
                    
                    
                    if index == ik.boneArray.count-1 {
                        //print("***** after bone *****")
                        //self.printTransform(targetBone)
                        //bone.printWorldTransform()
                        //printWorldTransform(bone.presentationNode)
                        
                        if bone.childNodes.count > 0 {
                            //print("***** after child *****")
                            //printWorldTransform(bone.childNodes[0])
                            //printWorldTransform(bone.childNodes[0].presentationNode)
                            //printWorldPosition(bone.childNodes[0])
                        }
                        
                        //print("***** target after *****")
                        //printWorldTransform(targetBone.presentationNode)
                        
                    }
                    
                    // MARK: DEBUG
                    //print("")
                    //print("")
                    //print("\(bone.name!) - \(targetBone.name!) -> \(ikBone.name!)")
                    //let afterBonePosition = getWorldPosition(bone.presentationNode)
                    //let afterTargetPosition = getWorldPosition(targetBone.presentationNode)
              
                    /*
                    if equalV3(targetPosition, afterTargetPosition) {
                        print("!!!!! targetPosition is not changed !!!!!")
                        print("   \(targetPosition.x), \(targetPosition.y), \(targetPosition.z)")
                    }
                    */
                    
                    /*
                    var afterV1 = sub(afterBonePosition, afterTargetPosition)
                    var afterV2 = sub(afterBonePosition, ikPosition)
                    
                    afterV1 = normalize(afterV1)
                    afterV2 = normalize(afterV2)
                    
                    var afterDiff = sub(afterV1, afterV2)
                    let afterX2 = afterDiff.x * afterDiff.x
                    let afterY2 = afterDiff.y * afterDiff.y
                    let afterZ2 = afterDiff.z * afterDiff.z
                    let afterDiffLength = afterX2 + afterY2 + afterZ2
                    */
                    
                    //afterCheck(bone)
                    
                    //print("diff: \(beforeDiffLength) -> \(afterDiffLength) (\(beforeDiffLength - afterDiffLength))")
                    
                    // <update bone matrices>
                } // boneArray
            } // iteration
        } // ikArray
    }
    
    private func sub(v1: SCNVector3, _ v2: SCNVector3) -> SCNVector3 {
        var v = SCNVector3()
        v.x = v1.x - v2.x
        v.y = v1.y - v2.y
        v.z = v1.z - v2.z
        
        return v
    }
    
    private func dot(v1: SCNVector3, _ v2: SCNVector3) -> Float {
        return Float(v1.x * v2.x + v1.y * v2.y + v1.z * v2.z)
    }
    
    private func cross(v1: SCNVector3, _ v2: SCNVector3) -> SCNVector3 {
        var v = SCNVector3()
        v.x = v1.y * v2.z - v1.z * v2.y
        v.y = v1.z * v2.x - v1.x * v2.z
        v.z = v1.x * v2.y - v1.y * v2.x
        
        return v
    }
    
    private func normalize(v1: SCNVector3) -> SCNVector3 {
        var v = SCNVector3()
        let r = 1.0 / sqrt(v1.x * v1.x + v1.y * v1.y + v1.z * v1.z)
        
        v.x = v1.x * r
        v.y = v1.y * r
        v.z = v1.z * r
        
        return v
    }
    
    private func cross(q1: SCNVector4, _ q2: SCNVector4) -> SCNVector4 {
        var q = SCNVector4()
        q.x = q1.x * q2.w + q1.w * q2.x + q1.y * q2.z - q1.z * q2.y
        q.y = q1.y * q2.w + q1.w * q2.y + q1.z * q2.x - q1.x * q2.z
        q.z = q1.z * q2.w + q1.w * q2.z + q1.x * q2.y - q1.y * q2.x
        q.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
        
        return q
    }
    
    private func cross(v1: SCNVector3, _ mat: SCNMatrix4, includeTranslate: Bool = false) -> SCNVector3 {
        var v = SCNVector3()
        
        v.x = v1.x * mat.m11 + v1.y * mat.m21 + v1.z * mat.m31
        v.y = v1.x * mat.m12 + v1.y * mat.m22 + v1.z * mat.m32
        v.z = v1.x * mat.m13 + v1.y * mat.m23 + v1.z * mat.m33
 
        if includeTranslate {
            v.x += mat.m41
            v.y += mat.m42
            v.z += mat.m43
        }
        
        return v
    }
    
    private func inverseCross(v1: SCNVector3, _ mat: SCNMatrix4, includeTranslate: Bool = false) -> SCNVector3 {
        var v = SCNVector3()
        
        v.x = v1.x * mat.m11 + v1.y * mat.m12 + v1.z * mat.m13
        v.y = v1.x * mat.m21 + v1.y * mat.m22 + v1.z * mat.m23
        v.z = v1.x * mat.m31 + v1.y * mat.m32 + v1.z * mat.m33
        
        if includeTranslate {
            v.x += mat.m14
            v.y += mat.m24
            v.z += mat.m34
        }
        
        return v
    }
    
    func printWorldTransform(n: SCNNode! = nil) {
        //var m = self.presentationNode.worldTransform
        var m = self.worldTransform
        if n != nil {
            //m = n.presentationNode.worldTransform
            m = n.worldTransform
        }
        print("\(m.m11) \(m.m12) \(m.m13) \(m.m14)")
        print("\(m.m21) \(m.m22) \(m.m23) \(m.m24)")
        print("\(m.m31) \(m.m32) \(m.m33) \(m.m34)")
        print("\(m.m41) \(m.m42) \(m.m43) \(m.m44)")
    }
    
    func printWorldPosition(n: SCNNode! = nil) {
        let pos = getWorldPosition(n)
        
        print("\(pos.x) \(pos.y) \(pos.z)")
    }
    
    func getWorldPosition(n: SCNNode! = nil) -> SCNVector3 {
        var m: SCNMatrix4
        if n == nil {
            m = self.worldTransform
        } else {
            m = n.worldTransform
        }
        
        var v = SCNVector3()
        v.x = m.m41
        v.y = m.m42
        v.z = m.m43
        
        return v
    }
    
    func printRotation(n: SCNNode! = nil) {
        var v: SCNVector4
        if n == nil {
            v = self.rotation
        } else {
            v = n.rotation
        }
        print("\(v.x) \(v.y) \(v.z) \(v.w)")
    }
    
    func rotationToQuat(rot: SCNVector4) -> SCNVector4 {
        var quat = SCNVector4()
        if rot.x == 0 && rot.y == 0 && rot.z == 0 {
            quat.x = 0
            quat.y = 0
            quat.z = 0
            quat.w = 1.0
        } else {
            let r = 1.0 / sqrt(rot.x * rot.x + rot.y * rot.y + rot.z * rot.z)
            let cosW = cos(rot.w)
            let sinW = sin(rot.w) * r
            quat.x = rot.x * sinW
            quat.y = rot.y * sinW
            quat.z = rot.z * sinW
            quat.w = cosW
        }
        
        return quat
    }
    
    func quatToRotation(var quat: SCNVector4) -> SCNVector4 {
        var rot = SCNVector4()
        
        if quat.x == 0 && quat.y == 0 && quat.z == 0 {
            rot.x = 0
            rot.y = 0
            rot.z = 0
            rot.w = 0
        } else {
            rot.x = quat.x
            rot.y = quat.y
            rot.z = quat.z
            
            if quat.w > 1 {
                quat.w = 1.0
            } else if quat.w < -1 {
                quat.w = -1.0
            }
            
            let w = acos(quat.w)
            
            if w.isNaN {
                rot.w = 0
            } else {
                rot.w = w
            }
        }
        
        return rot
    }
    
    var checkParentPosition: SCNVector3 = SCNVector3()
    var checkParentRotation: SCNVector4 = SCNVector4()
    var checkParentPresentPosition: SCNVector3 = SCNVector3()
    var checkParentPresentRotation: SCNVector4 = SCNVector4()
    var checkBonePosition: SCNVector3 = SCNVector3()
    var checkBoneRotation: SCNVector4 = SCNVector4()
    var checkBonePresentPosition: SCNVector3 = SCNVector3()
    var checkBonePresentRotation: SCNVector4 = SCNVector4()
    var checkBoneWorldPosition: SCNVector3 = SCNVector3()
    var checkChildPosition: SCNVector3 = SCNVector3()
    var checkChildRotation: SCNVector4 = SCNVector4()
    var checkChildPresentPosition: SCNVector3 = SCNVector3()
    var checkChildPresentRotation: SCNVector4 = SCNVector4()
    var checkChildWorldPosition: SCNVector3 = SCNVector3()
    var checkChildPresentWorldPosition: SCNVector3 = SCNVector3()
    var checkGrandChildWorldPosition: SCNVector3 = SCNVector3()

    func beforeCheck(n: SCNNode) {
        checkParentPosition = (n.parentNode?.position)!
        checkParentRotation = (n.parentNode?.rotation)!
        checkParentPresentPosition = (n.parentNode?.presentationNode.position)!
        checkParentPresentRotation = (n.parentNode?.presentationNode.rotation)!
        checkBonePosition = n.position
        checkBoneRotation = n.rotation
        checkBonePresentPosition = n.presentationNode.position
        checkBonePresentRotation = n.presentationNode.rotation
        checkBoneWorldPosition = getWorldPosition(n)
        
        if n.childNodes.count > 0 {
            let child = n.childNodes[0]
            checkChildPosition = child.position
            checkChildRotation = child.rotation
            checkChildPresentPosition = child.presentationNode.position
            checkChildPresentRotation = child.presentationNode.rotation
            checkChildWorldPosition = getWorldPosition(child)
            checkChildPresentWorldPosition = getWorldPosition(child.presentationNode)
            
            if child.childNodes.count > 0 {
                let grandChild = child.childNodes[0]
                checkGrandChildWorldPosition = getWorldPosition(grandChild)
            }
        }
    }
    
    func afterCheck(n: SCNNode) {
        let a_checkParentPosition = (n.parentNode?.position)!
        if !equalV3(checkParentPosition, a_checkParentPosition) {
            print("***** checkParentPosition *****")
        }
        
        let a_checkParentRotation = (n.parentNode?.rotation)!
        if !equalV4(checkParentRotation, a_checkParentRotation) {
            print("***** checkParentRotation *****")
        }
        
        let a_checkParentPresentPosition = (n.parentNode?.presentationNode.position)!
        if !equalV3(checkParentPresentPosition, a_checkParentPresentPosition) {
            print("***** checkParentPresentPosition *****")
        }
        
        let a_checkParentPresentRotation = (n.parentNode?.presentationNode.rotation)!
        if !equalV4(checkParentPresentRotation, a_checkParentPresentRotation) {
            print("***** checkParentPresentRotation *****")
        }
        
        let a_checkBonePosition = n.position
        if !equalV3(checkBonePosition, a_checkBonePosition) {
            print("***** checkBonePosition *****")
        }
        
        let a_checkBoneRotation = n.rotation
        if !equalV4(checkBoneRotation, a_checkBoneRotation) {
            print("***** checkBoneRotation *****")
        }
        
        let a_checkBonePresentPosition = n.presentationNode.position
        if !equalV3(checkBonePresentPosition, a_checkBonePresentPosition) {
            print("***** checkBonePresentPosition *****")
        }
        
        let a_checkBonePresentRotation = n.presentationNode.rotation
        if !equalV4(checkBonePresentRotation, a_checkBonePresentRotation) {
            print("***** checkBonePresentRotation *****")
        }
        
        let a_checkBoneWorldPosition = getWorldPosition(n)
        if !equalV3(checkBoneWorldPosition, a_checkBoneWorldPosition) {
            print("***** checkBoneWorldPosition *****")
        }
        
        if n.childNodes.count > 0 {
            let child = n.childNodes[0]
            let a_checkChildPosition = child.position
            if !equalV3(checkChildPosition, a_checkChildPosition) {
                print("***** checkChildPosition *****")
            }
            
            let a_checkChildRotation = child.rotation
            if !equalV4(checkChildRotation, a_checkChildRotation) {
                print("***** checkChildRotation *****")
            }
            
            let a_checkChildPresentPosition = child.presentationNode.position
            if !equalV3(checkChildPresentPosition, a_checkChildPresentPosition) {
                print("***** checkChildPresentPosition *****")
            }
            
            let a_checkChildPresentRotation = child.presentationNode.rotation
            if !equalV4(checkChildPresentRotation, a_checkChildPresentRotation) {
                print("***** checkChildPresentRotation *****")
            }
            
            let a_checkChildWorldPosition = getWorldPosition(child)
            if !equalV3(checkChildWorldPosition, a_checkChildWorldPosition) {
                print("***** checkChildWorldPosition *****")
            }
            
            let a_checkChildPresentWorldPosition = getWorldPosition(child.presentationNode)
            if !equalV3(checkChildPresentWorldPosition, a_checkChildPresentWorldPosition) {
                print("***** checkChildPresentWorldPosition *****")
            }
            
            if child.childNodes.count > 0 {
                let grandChild = child.childNodes[0]
                let a_checkGrandChildWorldPosition = getWorldPosition(grandChild)
                
                if !equalV3(checkGrandChildWorldPosition, a_checkGrandChildWorldPosition) {
                    print("***** checkGrandChildPresentWorldPosition *****")
                }
            }
        }
        
    }
    
    func equalV3(v1: SCNVector3, _ v2: SCNVector3) -> Bool {
        return v1.x == v2.x && v1.y == v2.y && v1.z == v2.z
    }
    
    func equalV4(v1: SCNVector4, _ v2: SCNVector4) -> Bool {
        return v1.x == v2.x && v1.y == v2.y && v1.z == v2.z && v1.w == v2.w
    }
}
