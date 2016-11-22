//
//  MMDSceneSource.swift
//  MMDSceneKit
//
//  Created by magicien on 12/9/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

#if os(iOS) || os(tvOS) || os(watchOS)
        import UIKit
#elseif os(OSX)
        import AppKit
#endif

public enum MMDFileType {
    case pmm, pmd, vmd, x, pmx, unknown
}

open class MMDSceneSource: SCNSceneSource {
    /// file type which is detected by file header
    open fileprivate(set) var fileType: MMDFileType! = .unknown
    
    fileprivate var directoryPath: String! = nil
    fileprivate var workingScene: SCNScene! = nil
    fileprivate var workingNode: MMDNode! = nil

    #if !os(watchOS)
        private var workingAnimationGroup: CAAnimationGroup! = nil
    #endif
    
    // MARK: - Initialize
    public override init() {
        super.init()
    }
    
    /**
        Initializes a scene source for reading the scene graph contained in an NSData object.
        - parameter data: A data object containing a scene file in MMD file format.
        - parameter options: ignored. just for compatibility of SCNSceneSource.
    */
    public override convenience init?(data: Data, options: [SCNSceneSource.LoadingOption : Any]? = nil) {
        self.init()
        self.loadData(data, options: options)
    }
    
    fileprivate func loadData(_ data: Data, options: [SCNSceneSource.LoadingOption : Any]? = nil) {
        self.workingScene = SCNScene()
        
        _ = checkFileTypeFromData(data)
        if self.fileType == .pmd {
            if let pmdNode = MMDPMDReader.getNode(data, directoryPath: self.directoryPath) {
                //self.workingScene.rootNode.addChildNode(pmdNode)
                self.workingNode = pmdNode
            }
        }else if self.fileType == .vmd {
            #if os(watchOS)
                // CAAnimation is not supported in watchOS
            #else
                if let vmdAnimation = MMDVMDReader.getAnimation(data) {
                    //self.workingScene.rootNode.addChildNode(vmdNode)
                    self.workingAnimationGroup = vmdAnimation
                }
            #endif
        }else if self.fileType == .pmm {
            if let pmmScene = MMDPMMReader.getScene(data, directoryPath: self.directoryPath) {
                for node in pmmScene.rootNode.childNodes {
                    self.workingScene.rootNode.addChildNode(node)
                }
            }
        }else if self.fileType == .x {
            if let xNode = MMDXReader.getNode(data, directoryPath: self.directoryPath) {
                self.workingNode = xNode
            }
        }else if self.fileType == .pmx {
            if let pmxNode = MMDPMXReader.getNode(data, directoryPath: self.directoryPath) {
                //self.workingScene.rootNode.addChildNode(pmdNode)
                self.workingNode = pmxNode
            }
        }else{
            // unknown file
        }
    }

    
    /**
        Initializes a scene source for reading the scene graph from a specified file.
        - parameter url: A URL identifying the location of a scene file in MMD file format.
        - parameter options: ignored. just for compatibility of SCNSceneSource.
    */
    public override convenience init?(url: URL, options: [SCNSceneSource.LoadingOption : Any]? = nil) {
        self.init()
    }

    /**
        Initializes a scene source for reading the scene graph from a specified file.
        - parameter path: A path identifying the location of a scene file in MMD file format.
        - parameter options: ignored. just for compatibility of SCNSceneSource.
    */
    public convenience init?(path: String, options: [SCNSceneSource.LoadingOption : Any]? = nil) {
        self.init()
        self.directoryPath = (path as NSString).deletingLastPathComponent

        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        if data == nil {
            print("data is nil...")
            return nil
        } else {
            self.loadData(data!, options: options)
        }
    }
    
    /**
         Initializes a scene source for reading the scene graph from a specified file.
         - parameter url: A URL identifying the location of a scene file in MMD file format.
         - parameter options: ignored.
    */
    public convenience init?(named name: String, options: [SCNSceneSource.LoadingOption : Any]? = nil) {
        let filePath = Bundle.main.path(forResource: name, ofType: nil)
        guard let path = filePath else {
            print("error: file \(name) not found.")
            return nil
        }
        self.init(path: path, options: options)
    }
    
    /**
        Return an array of MMDNode objects which represent model node
    */
    open func modelNodes() -> [MMDNode]! {
        var nodeArray = [MMDNode]()
        
        if self.fileType == .pmd || self.fileType == .pmx || self.fileType == .x {
            print("add workingNode: \(self.workingNode)")
            nodeArray.append(self.workingNode) // FIXME: clone node
        }else if self.fileType == .pmm {
            for node in self.workingScene.rootNode.childNodes {
                if let mmdNode = node as? MMDNode {
                    nodeArray.append(mmdNode) // FIXME: clone node
                }
            }
        }
        
        return nodeArray
    }

    open func cameraNodes() -> [MMDNode]! {
        let cameraArray = [MMDNode]()
        
        return cameraArray
    }
    
    open func lightNodes() -> [MMDNode]! {
        let lightArray = [MMDNode]()
        
        return lightArray
    }
    
    open func getModel() -> MMDNode? {
        if self.fileType == .pmd || self.fileType == .pmx || self.fileType == .x {
            // FIXME: clone node
            return self.workingNode
        }else if self.fileType == .pmm {
            for node in self.workingScene.rootNode.childNodes {
                if let mmdNode = node as? MMDNode {
                    return mmdNode
                }
            }
        }
        return nil
    }
    
#if !os(watchOS)
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
    
    open func getMotion() -> CAAnimationGroup? {
        return self.workingAnimationGroup
    }
#endif
    
    fileprivate func checkFileTypeFromData(_ data: Data) -> MMDFileType! {
        let byte3 = data.subdata(in: 0..<3)
        let str3 = NSString.init(data: byte3, encoding: String.Encoding.shiftJIS.rawValue)
        
        if str3 == "Pmd" {
            self.fileType = .pmd
            return .pmd
        }

        let byte4 = data.subdata(in: 0..<4)
        let str4 = NSString.init(data: byte4, encoding: String.Encoding.shiftJIS.rawValue)

        if str4 == "xof " {
            self.fileType = .x
            return .x
        }
        if str4 == "PMX " {
            self.fileType = .pmx
            return .pmx
        }
        
        let byte24 = data.subdata(in: 0..<24)
        let str24 = NSString.init(data: byte24, encoding: String.Encoding.shiftJIS.rawValue)

        if str24 == "Polygon Movie maker 0001" || str24 == "Polygon Movie maker 0002" {
            self.fileType = .pmm
            return .pmm
        }

        let byte25 = data.subdata(in: 0..<25)
        let str25 = NSString.init(data: byte25, encoding: String.Encoding.shiftJIS.rawValue)

        if str25 == "Vocaloid Motion Data 0002" {
            self.fileType = .vmd
            return self.fileType
        }
        
        self.fileType = .unknown
        return .unknown
    }
    
    // MARK: - Loading PMM File
    
    fileprivate func loadPMMFile() -> [MMDNode]? {
        return nil
    }

    
    // MARK: - for Debug

    /**
    show bone tree for debug
    - parameter bone: root node of the bone tree
    - parameter prefix: prefix for indent
    */
    fileprivate func showBoneTree(_ bone: SCNNode, prefix: String = "") {
        print(prefix + bone.name! + "(\(bone.position.x), \(bone.position.y), \(bone.position.z))")
        
        for child in bone.childNodes {
            showBoneTree(child, prefix: "    " + prefix)
        }
    }
    
}
