//
//  MMDXReader.swift
//  MMDSceneKit
//
//  Created by Yuki OHNO on 12/18/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

class MMDXReader: MMDReader {
    private var workingNode: MMDNode! = nil
    
    private var text: String! = nil
    private var offset = 0
    
    /**
     */
    static func getNode(data: NSData, directoryPath: String! = "") -> MMDNode? {
        let reader = MMDXReader(data: data, directoryPath: directoryPath)
        let node = reader.loadXFile()
        
        return node
    }
    
    // MARK: - Loading X File
    private func loadXFile() -> MMDNode? {
        // initialize working variables
        self.workingNode = MMDNode()

        
        
        return self.workingNode
    }
    
    private func XFileHeader(parent: MMDNode? = nil) -> Bool {
        
        moveIndex(16)
        
        
        
        return true
    }
    
    private func moveIndex(len: Int) {
        //self.text = self.text.substringFromIndex(len)
        self.offset += len
    }
}
