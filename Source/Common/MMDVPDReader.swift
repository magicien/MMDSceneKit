//
//  MMDVPDReader.swift
//  MMDSceneKit
//
//  Created by magicien on 12/3/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit

#if os(watchOS)
    
    class MMDVPDReader: MMDReader {
        // CAAnimation is not supported in watchOS
    }
    
#else

class MMDVPDReader: MMDReader {
    // MARK: - property for VPD File
    private var workingAnimationGroup: CAAnimationGroup! = nil
    
    /**
     */
    static func getAnimation(_ data: Data, directoryPath: String! = "") -> CAAnimationGroup? {
        let reader = MMDVPDReader(data: data, directoryPath: directoryPath)
        let animation = reader.loadVPDFile()
        
        return animation
    }    
    
    // MARK: - Loading VPD File
    
    /**
     */
    private func loadVPDFile() -> CAAnimationGroup? {
        let data = String(data: self.binaryData, encoding: .shiftJIS)
        guard let lines = data?.components(separatedBy: "\r\n") else { return nil }
        
        self.workingAnimationGroup = CAAnimationGroup()
        self.workingAnimationGroup.animations = [CAAnimation]()
        
        let magic = lines[0]
        if magic != "Vocaloid Pose Data file" {
            print("Unknown file format: \(magic)")
            return nil
        }
        
        let modelName = lines[2].components(separatedBy: ";")[0]
        let numBonesText = lines[3].components(separatedBy: ";")[0]
        guard let numBones = Int(numBonesText) else { return nil }
        
        var line = 5
        for boneNo in 0..<numBones {
            let boneName = lines[line+0].components(separatedBy: "{")[1]
            let posText = lines[line+1].components(separatedBy: ";")[0].components(separatedBy: ",")
            let rotText = lines[line+2].components(separatedBy: ";")[0].components(separatedBy: ",")

            let posX = getFloatFromText(posText[0])
            let posY = getFloatFromText(posText[1])
            let posZ = getFloatFromText(posText[2])
            let pos = SCNVector3Make(OSFloat(posX), OSFloat(posY), OSFloat(-posZ))
            
            let rotX = getFloatFromText(rotText[0])
            let rotY = getFloatFromText(rotText[1])
            let rotZ = getFloatFromText(rotText[2])
            let rotW = getFloatFromText(rotText[3])
            let rot = SCNVector4Make(OSFloat(-rotX), OSFloat(-rotY), OSFloat(rotZ), OSFloat(rotW))

            let posMotion = CAKeyframeAnimation(keyPath: "/\(boneName).transform.translation")
            let rotMotion = CAKeyframeAnimation(keyPath: "/\(boneName).transform.quaternion")
            
            posMotion.values = [NSValue(scnVector3: pos)]
            rotMotion.values = [NSValue(scnVector4: rot)]
            
            posMotion.keyTimes = [NSNumber(value: 0.0)]
            rotMotion.keyTimes = [NSNumber(value: 0.0)]
            
            print("boneNo: \(boneNo)")
            print("boneName: \(boneName)")
            print("position: \(pos)")
            print("rotation: \(rot)")
            
            self.workingAnimationGroup.animations!.append(posMotion)
            self.workingAnimationGroup.animations!.append(rotMotion)
            
            line += 5
        }
        
        self.workingAnimationGroup.duration = 0
        self.workingAnimationGroup.usesSceneTimeBase = false
        self.workingAnimationGroup.isRemovedOnCompletion = false
        self.workingAnimationGroup.fillMode = kCAFillModeForwards

        return self.workingAnimationGroup
    }
    
    func getFloatFromText(_ text: String) -> Float {
        let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if let value = Float(trimmedText) {
            return value
        }
        
        return 0
    }
}

#endif
