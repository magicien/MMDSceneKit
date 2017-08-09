//
//  MMDTechnique.swift
//  MMDSceneKit
//
//  Created by magicien on 2017/08/02.
//  Copyright © 2017年 DarkHorse. All rights reserved.
//

/*
import SceneKit

open class MMDTechnique: SCNTechnique {
    override init() {
        var nsDict: NSDictionary?
        if let path = Bundle(for: MMDTechnique.self).path(forResource: "MMDShader", ofType: "plist") {
            nsDict = NSDictionary(contentsOfFile: path)
        }
        guard let dict = nsDict else {
            super.init()
            return
        }
        
        if let d = dict as? [String : AnyObject] {
            super.init(dictionary: d)!
        } else {
            super.init()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func techniqueWithDictionary(_ dictionary: [String : Any]) {
        return super.techniqueWithDictionary(dictionary)
    }
}
*/
