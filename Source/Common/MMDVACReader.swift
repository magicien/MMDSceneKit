//
//  MMDVACReader.swift
//  MMDSceneKit
//
//  Created by magicien on 11/25/16.
//  Copyright © 2016 DarkHorse. All rights reserved.
//

import SceneKit

class MMDVACReader: MMDReader {
    static func getNode(_ data: Data, directoryPath: String! = "") -> MMDNode? {
        let reader = MMDVACReader(data: data, directoryPath: directoryPath)
        let node = reader.loadVACFile()
        
        return node
    }
    
    // MARK: - Loading VMD File
    
    /**
     */
    private func loadVACFile() -> MMDNode? {
        let data = String(data: self.binaryData, encoding: .shiftJIS)
        if let lines = data?.components(separatedBy: "\r\n") {
            if lines.count < 6 {
                return nil
            }
            let name = lines[0]
            let fileName = lines[1]
            let scaleStr = lines[2]
            let positions = lines[3].components(separatedBy: ",")
            let rotations = lines[4].components(separatedBy: ",")
            let boneName = lines[5]
            
            let xFilePath = (self.directoryPath as NSString).appendingPathComponent(fileName)
            var model: MMDNode? = nil
            if let scene = MMDSceneSource(path: xFilePath) {
                model = scene.getModel()
            } else {
                print("can't read file: \(xFilePath)")
            }
            
            if let mmdModel = model {
                mmdModel.name = name
                
                if let scale = Float(scaleStr) {
                    let s = OSFloat(scale * 10.0)
                    mmdModel.scale = SCNVector3Make(s, s, s)
                } else {
                    mmdModel.scale = SCNVector3Make(10.0, 10.0, 10.0)
                }
                
                if positions.count >= 3 {
                    let posX = Float(positions[0])
                    let posY = Float(positions[1])
                    let posZ = Float(positions[2])
                    if let x = posX, let y = posY, let z = posZ {
                        mmdModel.position = SCNVector3Make(OSFloat(x), OSFloat(y), OSFloat(z))
                    }
                }
                
                if rotations.count >= 3 {
                    let rotX = Float(rotations[0])
                    let rotY = Float(rotations[1])
                    let rotZ = Float(rotations[2])
                    if let x = rotX, let y = rotY, let z = rotZ {
                        // TODO: implement
                    }
                }
                
                return mmdModel
            }
        }
        
        return nil
    }
}

