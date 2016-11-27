//
//  MMDNode.swift
//  MMDSceneKit
//
//  Created by magicien on 12/9/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

public enum MMDNodeType {
    case rotate
    case rotate_TRANSLATE
    case ik
    case unknown
    case ik_CHILD
    case rotate_CHILD
    case ik_TARGET
    case hidden
    case twist
    case roll
}

open class MMDFloat: NSObject {
    open var value: Float = 0.0
}

open class DummyNode: NSObject {
    override open func value(forUndefinedKey key: String) -> Any? {
        print("unknown key: \(key)")
        return self
    }
}

#if os(watchOS)
    @objc public protocol EmptyDelegate {
        // nothing to do
    }
    public typealias MMDNodeProgramDelegate = EmptyDelegate
#else
    public typealias MMDNodeProgramDelegate = SCNProgramDelegate
#endif

open class MMDNode: SCNNode, MMDNodeProgramDelegate {
    open internal(set) var physicsBehaviors: [SCNPhysicsBehavior]! = []
    open internal(set) var type: MMDNodeType = .unknown
    open internal(set) var isKnee: Bool = false
    
    // FIXME: internal variant
    open var ikTargetBone: MMDNode? = nil
    //public var ikConstraint: SCNIKConstraint? = nil
    internal var ikConstraint: MMDIKConstraint? = nil
    open var ikArray: [MMDIKConstraint]? = nil

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
    open var vertexCount = 0
    open var vertexArray: [Float32]! = nil
    open var normalArray: [Float32]! = nil
    open var texcoordArray: [Float32]! = nil
    open var boneIndicesArray: [UInt16]! = nil
    open var boneWeightsArray: [Float32]! = nil
    open var indexCount = 0
    open var indexArray: [UInt16]! = nil
    open var materialCount = 0
    open var materialArray: [SCNMaterial]! = nil
    open var materialIndexCountArray: [Int]! = nil
    open var elementArray: [SCNGeometryElement]? = nil
    open var boneArray: [MMDNode]! = nil
    open var boneInverseMatrixArray: [NSValue]! = nil
    open var rootBone: MMDNode! = nil
    
    open var rotateEffector: MMDNode? = nil
    open var rotateEffectRate: Float = 0.0
    open var translateEffector: MMDNode? = nil
    open var translateEffectRate: Float = 0.0

    fileprivate var dummyNode: DummyNode = DummyNode()
    
    // FIXME: use morpher
    open var faceIndexArray: [Int]? = nil
    open var faceDataArray: [[Float32]]? = nil
    open var faceWeights: [MMDFloat]! = nil
    open var geometryMorpher: SCNMorpher! = nil

    fileprivate let faceWeightsPattern = Regexp("faceWeights\\[(\\d+)\\]")
    
    // for animation
    //open var parentNo: Int = -1
    //open var parentNodes: [MMDNode]? = nil
    //open dynamic var motionParentNode: MMDNode? = nil
    
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
    open func updateFace() {
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
    
    open func updateVertexData() {
        let vertexData = NSData(bytes: self.vertexArray, length: 4 * 3 * self.vertexCount)
        let normalData = NSData(bytes: self.normalArray, length: 4 * 3 * self.vertexCount)
        let texcoordData = NSData(bytes: self.texcoordArray, length: 4 * 2 * self.vertexCount)
        let boneIndicesData = NSData(bytes: self.boneIndicesArray, length: 2 * 2 * self.vertexCount)
        let boneWeightsData = NSData(bytes: self.boneWeightsArray, length: 4 * 2 * self.vertexCount)
        let indexData = NSData(bytes: self.indexArray, length: 2 * self.indexCount)
        
        let vertexSource = SCNGeometrySource(data: vertexData as Data, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        let normalSource = SCNGeometrySource(data: normalData as Data, semantic: SCNGeometrySource.Semantic.normal, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12)
        let texcoordSource = SCNGeometrySource(data: texcoordData as Data, semantic: SCNGeometrySource.Semantic.texcoord, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        let boneIndicesSource = SCNGeometrySource(data: boneIndicesData as Data, semantic: SCNGeometrySource.Semantic.boneIndices, vectorCount: Int(vertexCount), usesFloatComponents: false, componentsPerVector: 2, bytesPerComponent: 2, dataOffset: 0, dataStride: 4)
        let boneWeightsSource = SCNGeometrySource(data: boneWeightsData as Data, semantic: SCNGeometrySource.Semantic.boneWeights, vectorCount: Int(vertexCount), usesFloatComponents: true, componentsPerVector: 2, bytesPerComponent: 4, dataOffset: 0, dataStride: 8)
        
        var elementArray = [SCNGeometryElement]()
        var indexPos = 0
        for index in 0..<self.materialCount {
            let count = materialIndexCountArray[index]
            let length = count * 2
            let data =  indexData.subdata(with: NSRange(indexPos..<indexPos+length))
            
            let element = SCNGeometryElement(data: data, primitiveType: .triangles, primitiveCount: count / 3, bytesPerIndex: 2)
            
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
        
        let oldGeometryNode = self.childNode(withName: "Geometry", recursively: true)
        self.replaceChildNode(oldGeometryNode!, with: newGeometryNode)
    }

#if !os(watchOS)
    @nonobjc public func program(_ program: SCNProgram, handleError error: NSError) {
        print("GLSL compile error: \(error)")
    }
#endif
    
    override open func value(forUndefinedKey key: String) -> Any? {
        if key.hasPrefix("/") {
            let searchKey = (key as NSString).substring(from: 1)
            if let node = self.childNode(withName: searchKey, recursively: true) {
                return node
            }
            return self.dummyNode
        }
        
        //print("unknown key: \(key)")
            
        let result = self.faceWeightsPattern.matches(key)
        if result != nil {
            let index = Int(result![1])
            let value = self.faceWeights[index!]
            //print("match: \(value)")
            return value
        }
        
        if key == "kPivotKey" {
            return nil
        }
    
        //return self.dummyNode
        return super.value(forUndefinedKey: key) as AnyObject?
    }
    
    override open func setValue(_ value: Any?, forUndefinedKey key: String) {
        print("setValueForUndefinedKey: \(key)")
    }

#if !os(watchOS)
    override open func addAnimation(_ animation: CAAnimation, forKey key: String?) {
        let geometryNode = self.childNode(withName: "Geometry", recursively: true)
        
        // FIXME: clone values
        if let group = animation as? CAAnimationGroup {
            let newGroup = group.copy() as! CAAnimationGroup
            newGroup.animations = [CAAnimation]()
            
            if let animations = group.animations {
                for anim in animations {
                    let newAnim = anim.copy()
                    
                    if let keyAnim = newAnim as? CAKeyframeAnimation {
                        let boneNameKey = keyAnim.keyPath!.components(separatedBy: ".")[0]
                        let boneName = (boneNameKey as NSString).substring(from: 1)
                        let bone = self.childNode(withName: boneName, recursively: true)
                        
                        if boneNameKey == "morpher" {

                            if keyAnim.keyPath!.hasPrefix("morpher.weights.") {
                                //print("+++++ morpher Animation - \(keyAnim.keyPath!)")
                                let faceName = (keyAnim.keyPath! as NSString).substring(from: 16)
                                var faceIndex = -1
                                
                                // search face name from geometry node
                                for index in 0..<geometryNode!.morpher!.targets.count {
                                    if geometryNode!.morpher!.targets[index].name == faceName {
                                        faceIndex = index
                                        break
                                    }
                                }
                                
                                if faceIndex >= 0 {
                                    var newKeyPath: String! = "faceWeights[\(faceIndex)].value"
                                    if MMD_USES_SCNMORPHER {
                                        newKeyPath = "/Geometry.morpher.weights[\(faceIndex)]"
                                    }
                                    //print("Face: \(faceName), KeyPath: \(newKeyPath), duration: \(keyAnim.duration)")
                                    keyAnim.keyPath = newKeyPath
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
                        } else {
                            // The bone is not found. It might happen.
                            //print("missing bone: \(boneName)")
                        }
                    }else{
                        // not CAKeyframeAnimation: nothing to do so far
                    }
                    newGroup.animations!.append(newAnim as! CAAnimation)
                }
            }
            super.addAnimation(newGroup, forKey: key)
        }else{
            // not CAAnimationGroup: just call the superclass
            super.addAnimation(animation, forKey: key)
        }
    }
#endif
    
    /**
    update IK bone
    */
    open func updateIK() {
        if self.ikArray != nil {
            let zeroThreshold = Float(0.0000001)
            
            for ik in self.ikArray! {
                let ikBone = ik.ikBone
                let targetBone = ik.targetBone
                
                // <update ikBone>
                
                for _ in 0..<ik.iteration {
                    boneArrayLoop: for index in 0..<ik.boneArray.count {
                        let bone = ik.boneArray[index]
                        
                        // <update targetBone>
                        // <update bone>
                        let bonePosition = getWorldPosition(bone.presentation)
                        let targetPosition = getWorldPosition(targetBone?.presentation)
                        let ikPosition = getWorldPosition(ikBone?.presentation)
                        
                        var v1 = sub(bonePosition, targetPosition)
                        var v2 = sub(bonePosition, ikPosition)
                        
                        v1 = normalize(v1)
                        v2 = normalize(v2)
                        
                        let diff = sub(v1, v2)
                        let x2 = diff.x * diff.x
                        let y2 = diff.y * diff.y
                        let z2 = diff.z * diff.z
                        if Float(x2 + y2 + z2) < zeroThreshold {
                            break boneArrayLoop
                        }
                        
                        var v = cross(v1, v2)
                        // worldTransform -> localTransform (rotation)
                        v = inverseCross(v, bone.parent!.presentation.worldTransform)
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
                        
                        let orgQuat = rotationToQuat(bone.presentation.rotation)
                        quat = cross(quat, orgQuat)
                        
                        bone.rotation = quatToRotation(quat)
                        
                        if bone.isKnee {
                            if bone.eulerAngles.x < 0 {
                                quat.x = -quat.x
                                bone.rotation = quatToRotation(quat)
                                if bone.eulerAngles.x < 0 {
                                    //print("***************** ERROR *****************")
                                }
                            }
                        }
                        
                        
                        // <update bone matrices>
                    } // boneArray
                } // iteration
            } // ikArray
        }
        
        self.updateEffector()
    }
    
    open func updateEffector() {
        if let rotateEffector = self.rotateEffector {
            //print("\(self.name)")
            //print("    \(self.presentation.rotation)")
            var rot = rotateEffector.presentation.rotation
            if self.rotateEffectRate == 1.0 {
                self.rotation = rot
            } else {
                let quat = self.rotationToQuat(rot)
                let orgQuat = self.rotationToQuat(self.presentation.rotation)
                let newQuat = self.slerp(src: orgQuat, dst: quat, rate: self.rotateEffectRate)
                self.rotation = self.quatToRotation(newQuat)
            }
            //print("    \(self.presentation.rotation)")
        }
        
        if let translateEffector = self.translateEffector {
            let pos = translateEffector.position
            if self.translateEffectRate == 1.0 {
                self.position = pos
            } else {
                self.position.x = pos.x * OSFloat(self.translateEffectRate)
                self.position.y = pos.y * OSFloat(self.translateEffectRate)
                self.position.z = pos.z * OSFloat(self.translateEffectRate)
            }
        }
    }
    
    fileprivate func sub(_ v1: SCNVector3, _ v2: SCNVector3) -> SCNVector3 {
        var v = SCNVector3()
        v.x = v1.x - v2.x
        v.y = v1.y - v2.y
        v.z = v1.z - v2.z
        
        return v
    }
    
    fileprivate func dot(_ v1: SCNVector3, _ v2: SCNVector3) -> Float {
        return Float(v1.x * v2.x + v1.y * v2.y + v1.z * v2.z)
    }
    
    fileprivate func cross(_ v1: SCNVector3, _ v2: SCNVector3) -> SCNVector3 {
        var v = SCNVector3()
        v.x = v1.y * v2.z - v1.z * v2.y
        v.y = v1.z * v2.x - v1.x * v2.z
        v.z = v1.x * v2.y - v1.y * v2.x
        
        return v
    }
    
    fileprivate func normalize(_ v1: SCNVector3) -> SCNVector3 {
        var v = SCNVector3()
        let r = 1.0 / sqrt(v1.x * v1.x + v1.y * v1.y + v1.z * v1.z)
        
        v.x = v1.x * r
        v.y = v1.y * r
        v.z = v1.z * r
        
        return v
    }
    
    fileprivate func cross(_ q1: SCNVector4, _ q2: SCNVector4) -> SCNVector4 {
        var q = SCNVector4()
        q.x = q1.x * q2.w + q1.w * q2.x + q1.y * q2.z - q1.z * q2.y
        q.y = q1.y * q2.w + q1.w * q2.y + q1.z * q2.x - q1.x * q2.z
        q.z = q1.z * q2.w + q1.w * q2.z + q1.x * q2.y - q1.y * q2.x
        q.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
        
        return q
    }
    
    fileprivate func cross(_ v1: SCNVector3, _ mat: SCNMatrix4, includeTranslate: Bool = false) -> SCNVector3 {
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
    
    fileprivate func inverseCross(_ v1: SCNVector3, _ mat: SCNMatrix4, includeTranslate: Bool = false) -> SCNVector3 {
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
    
    func printWorldTransform(_ n: SCNNode! = nil) {
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
    
    func printWorldPosition(_ n: SCNNode! = nil) {
        let pos = getWorldPosition(n)
        
        print("\(pos.x) \(pos.y) \(pos.z)")
    }
    
    func getWorldPosition(_ n: SCNNode! = nil) -> SCNVector3 {
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
    
    func printRotation(_ n: SCNNode! = nil) {
        var v: SCNVector4
        if n == nil {
            v = self.rotation
        } else {
            v = n.rotation
        }
        print("\(v.x) \(v.y) \(v.z) \(v.w)")
    }
    
    func rotationToQuat(_ rot: SCNVector4) -> SCNVector4 {
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
    
    func quatToRotation(_ quat: SCNVector4) -> SCNVector4 {
        var quat = quat
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
    
    /*
    func mulQuat(_ q1: SCNVector4, _ q2: SCNVector4) -> SCNVector4 {
        var ans = SCNVector4()
        ans.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
        ans.x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y
        ans.y = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x
        ans.z = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w

        return ans
    }
    */
    func slerp(src: SCNVector4, dst: SCNVector4, rate: Float) -> SCNVector4 {
        var ans = SCNVector4()
        
        let dot = Float(src.x * dst.x + src.y * dst.y + src.z * dst.z + src.w * dst.w)
        let inv2 = 1 - dot * dot
        var inv = Float(0.0)
        
        if inv2 > 0.0 {
            inv = sqrt(inv2)
        }
        if inv == 0.0 {
            ans.x = src.x
            ans.y = src.y
            ans.z = src.z
            ans.w = src.w
        } else {
            let h = acos(dot)
            let t = h * rate
            let t0 = OSFloat(sin(h - t) / inv)
            let t1 = OSFloat(sin(t) / inv)
            
            ans.x = src.x * t0 + dst.x * t1
            ans.y = src.y * t0 + dst.y * t1
            ans.z = src.z * t0 + dst.z * t1
            ans.w = src.w * t0 + dst.w * t1
        }
        
        return ans
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

    func beforeCheck(_ n: SCNNode) {
        checkParentPosition = (n.parent?.position)!
        checkParentRotation = (n.parent?.rotation)!
        checkParentPresentPosition = (n.parent?.presentation.position)!
        checkParentPresentRotation = (n.parent?.presentation.rotation)!
        checkBonePosition = n.position
        checkBoneRotation = n.rotation
        checkBonePresentPosition = n.presentation.position
        checkBonePresentRotation = n.presentation.rotation
        checkBoneWorldPosition = getWorldPosition(n)
        
        if n.childNodes.count > 0 {
            let child = n.childNodes[0]
            checkChildPosition = child.position
            checkChildRotation = child.rotation
            checkChildPresentPosition = child.presentation.position
            checkChildPresentRotation = child.presentation.rotation
            checkChildWorldPosition = getWorldPosition(child)
            checkChildPresentWorldPosition = getWorldPosition(child.presentation)
            
            if child.childNodes.count > 0 {
                let grandChild = child.childNodes[0]
                checkGrandChildWorldPosition = getWorldPosition(grandChild)
            }
        }
    }
    
    func afterCheck(_ n: SCNNode) {
        let a_checkParentPosition = (n.parent?.position)!
        if !equalV3(checkParentPosition, a_checkParentPosition) {
            print("***** checkParentPosition *****")
        }
        
        let a_checkParentRotation = (n.parent?.rotation)!
        if !equalV4(checkParentRotation, a_checkParentRotation) {
            print("***** checkParentRotation *****")
        }
        
        let a_checkParentPresentPosition = (n.parent?.presentation.position)!
        if !equalV3(checkParentPresentPosition, a_checkParentPresentPosition) {
            print("***** checkParentPresentPosition *****")
        }
        
        let a_checkParentPresentRotation = (n.parent?.presentation.rotation)!
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
        
        let a_checkBonePresentPosition = n.presentation.position
        if !equalV3(checkBonePresentPosition, a_checkBonePresentPosition) {
            print("***** checkBonePresentPosition *****")
        }
        
        let a_checkBonePresentRotation = n.presentation.rotation
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
            
            let a_checkChildPresentPosition = child.presentation.position
            if !equalV3(checkChildPresentPosition, a_checkChildPresentPosition) {
                print("***** checkChildPresentPosition *****")
            }
            
            let a_checkChildPresentRotation = child.presentation.rotation
            if !equalV4(checkChildPresentRotation, a_checkChildPresentRotation) {
                print("***** checkChildPresentRotation *****")
            }
            
            let a_checkChildWorldPosition = getWorldPosition(child)
            if !equalV3(checkChildWorldPosition, a_checkChildWorldPosition) {
                print("***** checkChildWorldPosition *****")
            }
            
            let a_checkChildPresentWorldPosition = getWorldPosition(child.presentation)
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
    
    func equalV3(_ v1: SCNVector3, _ v2: SCNVector3) -> Bool {
        return v1.x == v2.x && v1.y == v2.y && v1.z == v2.z
    }
    
    func equalV4(_ v1: SCNVector4, _ v2: SCNVector4) -> Bool {
        return v1.x == v2.x && v1.y == v2.y && v1.z == v2.z && v1.w == v2.w
    }
    
    func printBoneTree(indent: String = "    ", myIndent: String = "") {
        let newIndent = myIndent + indent
        for child in self.childNodes {
            var childName = child.name
            if childName == nil {
                childName = "(no name)"
            }
            print("\(myIndent)\(childName)")
            if let mmdChild = child as? MMDNode {
                mmdChild.printBoneTree(indent: indent, myIndent: newIndent)
            }
        }
    }
    
    func printBoneList() {
        for (index, bone) in self.boneArray.enumerated() {
            var boneName = bone.name
            if boneName == nil {
                boneName = "(no name)"
            }
            print("\(index): \(boneName)")
        }
    }
}
