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
#elseif os(macOS)
        import AppKit
#endif

public enum MMDFileType {
    case pmm, pmd, vmd, vpd, x, vac, pmx, obj, dae, abc, scn, unknown
}

@objcMembers
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
    
    fileprivate func loadData(_ data: Data, options: [SCNSceneSource.LoadingOption : Any]? = nil, models: [MMDNode?]? = nil, motions: [CAAnimation?]? = nil) {
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
        }else if self.fileType == .vpd {
            #if os(watchOS)
                // CAAnimation is not supported in watchOS
            #else
                if let vpdAnimation = MMDVPDReader.getAnimation(data) {
                    self.workingAnimationGroup = vpdAnimation
                }
            #endif
        }else if self.fileType == .pmm {
            if let pmmScene = MMDPMMReader.getScene(data, directoryPath: self.directoryPath, models: models, motions: motions) {
                for node in pmmScene.rootNode.childNodes {
                    self.workingScene.rootNode.addChildNode(node)
                }
            }
        }else if self.fileType == .x {
            if let xNode = MMDXReader.getNode(data, directoryPath: self.directoryPath) {
                self.workingNode = xNode
            }
        }else if self.fileType == .vac {
            if let xNode = MMDVACReader.getNode(data, directoryPath: self.directoryPath) {
                self.workingNode = xNode
            }
        }else if self.fileType == .pmx {
            if let pmxNode = MMDPMXReader.getNode(data, directoryPath: self.directoryPath) {
                //self.workingScene.rootNode.addChildNode(pmdNode)
                self.workingNode = pmxNode
            }
        }else if self.fileType == .obj || self.fileType == .dae || self.fileType == .scn {
            if let sceneSource = SCNSceneSource(data: data, options: options) {
                do {
                    let scene = try sceneSource.scene(options: options)
                    let mmdNode = MMDNode()
                    for child in scene.rootNode.childNodes {
                        mmdNode.addChildNode(child)
                    }
                    self.workingNode = mmdNode
                }catch{
                    print("error: scene file loading error.")
                }
            }
        }else if self.fileType == .abc {
            // ?
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
        print("URL: \(url)")
        var urlString:String = url.absoluteString.removingPercentEncoding!
        if urlString.starts(with: "file:///") {
            let startIndex = urlString.index(urlString.startIndex, offsetBy: 7)
            urlString = String(urlString[startIndex...])
        }
        print("URL string: \(urlString)")
        
        self.init(path: urlString, options: options, models: nil, motions: nil)
    }

    /**
        Initializes a scene source for reading the scene graph from a specified file.
        - parameter path: A path identifying the location of a scene file in MMD file format.
        - parameter options: ignored. just for compatibility of SCNSceneSource.
    */
    @objc public convenience init?(path: String, options: [SCNSceneSource.LoadingOption : Any]? = nil, models: [MMDNode]? = nil, motions: [CAAnimation]? = nil) {
        self.init()
        self.directoryPath = (path as NSString).deletingLastPathComponent

        if path.hasSuffix(".vac") {
            self.fileType = .vac
        } else if path.hasSuffix(".obj") {
            self.fileType = .obj
        } else if path.hasSuffix(".dae") {
            self.fileType = .dae
        } else if path.hasSuffix(".abc") {
            self.fileType = .abc
        } else if path.hasSuffix(".scn") {
            self.fileType = .scn
        }

        if self.fileType == .obj {
            do {
                self.workingScene = try SCNScene(url: URL(fileURLWithPath: path), options: nil)
            } catch {
                print("SCNScene URL open error")
            }
            
            guard self.workingScene != nil else {
                fatalError("can't open obj file: \(path)")
            }
            
            self.workingNode = MMDNode()
            for child in self.workingScene.rootNode.childNodes {
                self.workingNode.addChildNode(child)
            }
            self.workingScene.rootNode.addChildNode(self.workingNode)
            return
        }
        
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        if data == nil {
            print("data is nil... (\(path))")
            return nil
        } else {
            var opt: [SCNSceneSource.LoadingOption: Any]
            if options != nil {
                opt = options!
            } else {
                opt = [:]
            }
            
            if opt[.assetDirectoryURLs] == nil {
                opt[.assetDirectoryURLs] = [URL(fileURLWithPath: self.directoryPath)]
            }
            self.loadData(data!, options: opt, models: models, motions: motions)
        }
        
        //if self.fileType == .unknown {
        //    let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        //    if data == nil {
        //        print("data is nil... (\(path))")
        //        return nil
        //    } else {
        //        self.loadData(data!, options: options, models: models, motions: motions)
        //    }
        //} else {
        //
        //}
    }
    
    /**
         Initializes a scene source for reading the scene graph from a specified file.
         - parameter named: A URL identifying the location of a scene file in MMD file format.
         - parameter options: ignored.
    */
    @objc
    public convenience init?(named name: String, options: [SCNSceneSource.LoadingOption : Any]? = nil, models: [MMDNode]? = nil) {
        let filePath = Bundle.main.path(forResource: name, ofType: nil)
        guard let path = filePath else {
            print("error: file \(name) not found.")
            return nil
        }
        self.init(path: path, options: options, models: models)
    }
    
    /**
        Return an array of MMDNode objects which represent model node
    */
    open func modelNodes() -> [MMDNode]! {
        var nodeArray = [MMDNode]()
        
        if self.fileType == .pmd || self.fileType == .pmx || self.fileType == .x || self.fileType == .vac {
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
    
    open func getScene() -> SCNScene? {
        return self.workingScene
    }
    
    open func getModel() -> MMDNode? {
        if self.fileType == .pmd || self.fileType == .pmx || self.fileType == .x || self.fileType == .vac || self.fileType == .obj {
            return self.workingNode
        }else if self.fileType == .pmm {
            for node in self.workingScene.rootNode.childNodes {
                if let mmdNode = node as? MMDNode {
                    return mmdNode
                }
            }
        }else{
            fatalError("getModel not implemented for fileType \(self.fileType)")
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

        
        let byte23 = data.subdata(in: 0..<23)
        let str23 = NSString.init(data: byte23, encoding: String.Encoding.shiftJIS.rawValue)

        if str23 == "Vocaloid Pose Data file" {
            self.fileType = .vpd
            return .vpd
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
        
        // TODO: check file content
        
        return self.fileType
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
