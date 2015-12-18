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
    private var workingScene: SCNScene! = nil
    private var workingNode: MMDNode! = nil
    private var workingAnimationGroup: CAAnimationGroup! = nil
    
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
        self.workingScene = SCNScene()
        
        checkFileTypeFromData(data)
        if self.fileType == .PMD {
            if let pmdNode = MMDPMDReader.getNode(data, directoryPath: self.directoryPath) {
                //self.workingScene.rootNode.addChildNode(pmdNode)
                self.workingNode = pmdNode
            }
        }else if self.fileType == .VMD {
            if let vmdAnimation = MMDVMDReader.getAnimation(data) {
                //self.workingScene.rootNode.addChildNode(vmdNode)
                self.workingAnimationGroup = vmdAnimation
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
            //if let pmxNode = loadPMDFile() {
            //    self.workingScene.rootNode.addChildNode(pmxNode)
            //}
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
    
    
    private func checkFileTypeFromData(data: NSData) -> MMDFileType! {
        let byte3 = data.subdataWithRange(NSRange.init(location: 0, length: 3))
        let str3 = NSString.init(data: byte3, encoding: NSShiftJISStringEncoding)

        if str3 == "Pmd" {
            self.fileType = .PMD
            return .PMD
        }

        let byte4 = data.subdataWithRange(NSRange.init(location: 0, length: 4))
        let str4 = NSString.init(data: byte4, encoding: NSShiftJISStringEncoding)

        if str4 == "xof " {
            self.fileType = .X
            return .X
        }
        if str4 == "PMX " {
            self.fileType = .PMX
            return .PMX
        }
        
        let byte24 = data.subdataWithRange(NSRange.init(location: 0, length: 24))
        let str24 = NSString.init(data: byte24, encoding: NSShiftJISStringEncoding)

        if str24 == "Polygon Movie maker 0002" {
            self.fileType = .PMM
            return .PMM
        }

        let byte25 = data.subdataWithRange(NSRange.init(location: 0, length: 25))
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
