//
//  CommonTypes.swift
//  MMDSceneKit
//
//  Created by magicien on 1/11/17.
//  Copyright © 2017 DarkHorse. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

#if os(iOS) || os(tvOS) || os(watchOS)
    public typealias OSFloat = Float
    public typealias OSColor = UIColor
    public typealias OSImage = UIImage
    
    extension CGColor {
        static public let black = UIColor.black.cgColor
        static public let white = UIColor.white.cgColor
        static public let clear = UIColor.clear.cgColor
    }
#elseif os(macOS)
    public typealias OSFloat = CGFloat
    public typealias OSColor = NSColor
    public typealias OSImage = NSImage
#endif

#if os(watchOS)
    public typealias CAAnimation = Any
    public typealias CAAnimationGroup = Any
#endif
