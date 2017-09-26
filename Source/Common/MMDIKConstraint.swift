//
//  MMDIKNode.swift
//  MMDSceneKit
//
//  Created by magicien on 12/20/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

open class MMDIKConstraint {
    public var boneArray: [MMDNode]! = []
    var minAngleArray: [Float]! = []
    var maxAngleArray: [Float]! = []
    public var ikBone: MMDNode! = nil
    public var targetBone: MMDNode! = nil
    var iteration: Int = 0
    var weight: Float = 0.0
    var linkNo: Int = -1
    var isEnable: Bool = true
    
    var angle: SCNVector3! = SCNVector3()
    var orgTargetPos: SCNVector3! = SCNVector3()
    var rotAxis: SCNVector3! = SCNVector3()
    var rotQuat: SCNVector4! = SCNVector4()
    var inverseMat: SCNMatrix4! = SCNMatrix4()
    var diff: SCNVector3! = SCNVector3()
    var effectorPos: SCNVector3! = SCNVector3()
    var targetPos: SCNVector3! = SCNVector3()

    /*
    let ikConstraintBlock = { (node: SCNNode, matrix: SCNMatrix4) -> SCNMatrix4 in
        let mmdNode = node as? MMDNode
        if(mmdNode == nil){
            return matrix
        }
        
        let optionalIK = mmdNode!.ikConstraint
        if(optionalIK == nil){
            return matrix
        }
        let ik = optionalIK as MMDIKConstraint!
        
        let zeroThreshold = 0.00000001
        //let targetMat = matrix
        let orgTargetPos = ik.targetBone.position
        let pos = SCNVector3(matrix.m41, matrix.m42, matrix.m43)
        let rotAxis = ik.rotAxis
        let rotQuat = ik.rotQuat
        let inverseMat = ik.inverseMat
        let diff = ik.diff
        let effectorPos = ik.effectorPos
        let targetPos = ik.targetPos
        
        /*
        for var i = ik!.boneArray.count; i>=0; i-- {
            ik.boneArray[i].updateMatrix()
        }
        ik.effectorBone.updateMatrix()
        */
        
        for calcCount in 0..<ik!.iteration {
            for linkIndex in 0..<ik.boneArray.count {
                let linkedBone = ik.boneArray[linkIndex]
                let effectorMat = ik.effectorBone.representNode.transform
                effectorPos.x = effectorMat.m41
                effectorPos.y = effectorMat.m42
                effectorPos.z = effectorMat.m43
                
                // inverseMat.inverseMatrix(linkedBone.representNode.transform)
                effectorPos = effectorPos * inverseMat
                targetPos = orgTargetPos * inverseMat
                
                diff = effectorPos - targetPos
                if diff.length() < zeroThreshold {
                    return matrix
                }
                
                effectorPos.normalize()
                targetPos.normalize()
                
                var eDotT = effectorPos.dot(targetPos)
                if(eDotT >  1.0) {
                    eDotT = 1.0
                }
                if(eDotT < -1.0) {
                    edotT = -1.0
                }
                
                var rotAngle = acos(eDotT)
                if rotAngle > ik.weight * (linkIndex + 1) * 4 {
                    rotAngle = ik.weight * (linkIndex + 1) * 4
                }
                
                rotAxis.cross(effectPos, targetPos)
                if rotAxis.length() < zeroThreshold) {
                    break
                }
                rotAxis.normalize()
                rotQuat.createAxis(rotAxis, rotAngle)
                rotQuat.normalize()
                if ik.minAngleArray[linkIndex] {
                    ik.limitAngle(ik.minAngleArray[linkIndex], ik.maxAngleArray[linkIndex])
                }
                
                linkedBone.rotate.cross(linkedBone.rotate, rotQuat)
                linkedBone.rotate.normalize()
                
                for var i = linkIndex; i>=0; i-- {
                    ik.boneList[i].updateMatrix()
                }
                ik.effectorBone.updateMatrix()
            }
        }
    }
    */
    
    func printInfo() {
        print("boneArray: \(self.boneArray.count)")
        for bone in self.boneArray {
            print("  \(String(describing: bone.name))")
        }
        
        print("minAngleArray: \(self.minAngleArray.count)")
        for val in self.minAngleArray {
            print("  \(val)")
        }
        
        print("maxAngleArray: \(self.maxAngleArray.count)")
        for val in self.maxAngleArray {
            print("  \(val)")
        }
        
        print("ikBone: \(String(describing: self.ikBone.name))")
        print("targetBone: \(String(describing: self.targetBone.name))")
        print("iteration: \(self.iteration)")
        print("weight: \(self.weight)")
        print("isEnable: \(self.isEnable)")
        print("")
    }
}
