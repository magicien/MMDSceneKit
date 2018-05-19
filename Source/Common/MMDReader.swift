//
//  MMDReader.swift
//  MMDSceneKit
//
//  Created by magicien on 12/17/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import Foundation
import SceneKit

let toonFiles: [String] = [
    "toon01.bmp",
    "toon02.bmp",
    "toon03.bmp",
    "toon04.bmp",
    "toon05.bmp",
    "toon06.bmp",
    "toon07.bmp",
    "toon08.bmp",
    "toon09.bmp",
    "toon10.bmp"
]

internal class MMDReader: NSObject {
    internal var directoryPath: String! = ""
    internal var binaryData: Data! = nil
    internal var length = 0
    internal var pos = 0
    
    #if os(iOS) || os(tvOS) || os(watchOS)
    static var toonTextures: [UIImage]! = nil
    #elseif os(macOS)
    static var toonTextures: [NSImage]! = nil
    #endif
    
    /**
     *
     * - parameter data:
     * - parameter directoryPath:
     */
    internal init(data: Data!, directoryPath: String! = "") {
        super.init()
        
        self.directoryPath = directoryPath
        self.binaryData = data
        self.length = data.count
        self.pos = 0
        
        if MMDReader.toonTextures == nil {
            #if os(iOS) || os(tvOS) || os(watchOS)
            MMDReader.toonTextures = [UIImage]()
            for fileName in toonFiles {
                #if os(watchOS)
                let path = Bundle(for: MMDReader.self).path(forResource: fileName, ofType: nil)!
                let image = UIImage(contentsOfFile: path)!
                #else
                let path = Bundle(for: MMDReader.self).path(forResource: fileName, ofType: nil)!
                let image = UIImage(contentsOfFile: path)!
                #endif
                
                MMDReader.toonTextures.append(image)
            }
            #elseif os(macOS)
            MMDReader.toonTextures = [NSImage]()
            for fileName in toonFiles {
                let path = Bundle(for: MMDReader.self).path(forResource: fileName, ofType: nil)
                let image = NSImage(contentsOfFile: path!)
                MMDReader.toonTextures.append(image!)
            }
            #endif
        }
    }
    
    // MARK: - Utility functions
    
    /**
     * skip data
     * - parameter length: length of data you want to skip
     */
    internal func skip(_ length: Int) {
        self.pos += length
    }
    
    /**
     * get String data from MMD/PMD/VMD file
     * - parameter length: length of data you want to get (unit is byte)
     * - parameter encoding: encoding of string data. Default encoding of .mmd file is ShiftJIS
     * - returns: String data
     */
    internal func getString(length: Int, encoding: String.Encoding = String.Encoding.shiftJIS) -> NSString? {
        // check where null char is
        var strlen = length
        //var chars = Array<Int8>(repeating: 0, count: length)
        var chars = [UInt8](repeating: 0, count: length)
        //self.binaryData.copyBytes(to: &chars, range: NSRange.init(location: self.pos, length: length))
        self.binaryData.copyBytes(to: &chars, from: Range(self.pos..<self.pos+length))
        
        if encoding != String.Encoding.utf16LittleEndian {
            for index in 0..<length {
                if (chars[index] == 0) {
                    strlen = index
                    break
                }
            }
        }
        
        // encode string
        //let token = self.binaryData.subdata(in: NSRange.init(location: self.pos, length: strlen))
        let token = self.binaryData.subdata(in: Range(self.pos..<self.pos+strlen))
        let str = NSString.init(data: token, encoding: encoding.rawValue)
        
        self.pos += length
        
        return str
    }
    
    /**
     * read UInt8 data and return Int value from file
     * - returns: UInt8 data
     */
    internal func getUnsignedByte() -> UInt8 {
        var num: UInt8 = 0
        //let token = self.binaryData.subdata(in: Range.init(location: self.pos, length: 1))
        //token.copyBytes(to: &num, count: 1)
        self.binaryData.copyBytes(to: &num, from: Range(self.pos..<self.pos+1))
        
        self.pos += 1
        
        return num
    }
    
    /**
     * read UInt8 data and return Int value from file
     * - returns: UInt16 data
     */
    internal func getUnsignedShort() -> UInt16 {
        var num: UInt16 = 0
        //let token = self.binaryData.subdata(in: Range.init(location: self.pos, length: 2))
        //token.copyBytes(to: &num, count: 2)
        
        let pointer = UnsafeMutableBufferPointer<UInt16>(start: &num, count: 1)
        _ = self.binaryData.copyBytes(to: pointer, from: Range(self.pos..<self.pos+2))
        
        self.pos += 2
        
        return num
    }
    
    /**
     * read UInt32 data and return Int value from file
     * - returns: UInt32 data
     */
    internal func getUnsignedInt() -> UInt32 {
        var num: UInt32 = 0
        //let token = self.binaryData.subdata(in: Range.init(location: self.pos, length: 4))
        //token.copyBytes(to: &num, count: 4)
        
        let pointer = UnsafeMutableBufferPointer<UInt32>(start: &num, count: 1)
        _ = self.binaryData.copyBytes(to: pointer, from: Range(self.pos..<self.pos+4))
        
        self.pos += 4
        
        return num
    }
    
    /**
     * read Int32 data and return Int value from file
     * - returns: Signed Int32 data
     */
    internal func getInt() -> Int32 {
        var num: Int32 = 0
        //let token = self.binaryData.subdata(in: NSRange.init(location: self.pos, length: 4))
        //token.copyBytes(to: &num, count: 4)
        
        let pointer = UnsafeMutableBufferPointer<Int32>(start: &num, count: 1)
        _ = self.binaryData.copyBytes(to: pointer, from: Range(self.pos..<self.pos+4))
        
        self.pos += 4
        
        return num
    }
    
    /**
     * read Int data and return Int value from file
     * - returns: Signed Int data
     */
    internal func getIntOfLength(_ length: Int) -> Int {
        //var num: Int = 0
        
        if length <= 0 || length > 4 {
            return 0
        }
        
        //let token = self.binaryData.subdata(in: NSRange.init(location: self.pos, length: length))
        //token.copyBytes(to: &num, count: length)
        
        /*
         getUnsignedByte
         let pointer = UnsafeMutableBufferPointer<Unsign>(start: &num, count: 1)
         _ = self.binaryData.copyBytes(to: pointer, from: Range(self.pos..<self.pos+length))
         */
        
        if length == 1 {
            return Int(self.getUnsignedByte())
        } else if length == 2 {
            return Int(self.getUnsignedShort())
        } else if length == 4 {
            return Int(self.getUnsignedInt())
        }
        
        print("getIntOfLength: unsupported length: \(length)")
        return 0
    }
    
    /**
     * read 4 bytes float data and return Float32 value from file
     * - returns: Float data
     */
    internal func getFloat() -> Float32 {
        var num: Float32 = 0
        //let token = self.binaryData.subdata(in: Range(self.pos..<self.pos+4))
        //token.copyBytes(to: &num, from: Range(0..<4))
        
        let pointer = UnsafeMutableBufferPointer<Float32>(start: &num, count: 1)
        _ = self.binaryData.copyBytes(to: pointer, from: Range(self.pos..<self.pos+4))
        
        self.pos += 4
        
        return num
    }
    
    /**
     * read 4 bytes float data and return CGFloat value from file
     * - returns: Float data
     */
    internal func getCGFloat() -> CGFloat {
        let data = self.getFloat()
        return CGFloat(data)
    }
    
    /**
     * read binary data and return Data from file
     * - parameter length: length of data you want to get (unit is byte)
     * - returns: NSData value
     */
    internal func getData(_ length: Int) -> Data {
        let data = self.binaryData.subdata(in: Range(self.pos..<self.pos+length))
        self.pos += length
        
        return data
    }
    
    /**
     * return the data length which you can read
     * - returns: data length
     */
    internal func getAvailableDataLength() -> Int {
        return self.length - self.pos
    }
    
    /**
     * normalize SCNVector4 or SCNQuaternion value.
     * - parameter quat: data which has to be normalized. This variable is changed by this function.
     */
    internal func normalize(_ quat: inout SCNVector4) {
        let x2 = quat.x * quat.x
        let y2 = quat.y * quat.y
        let z2 = quat.z * quat.z
        let w2 = quat.w * quat.w
        
        let r = sqrt(x2 + y2 + z2 + w2)
        if r == 0 {
            // impossible to normalize
            return
        }
        let invr = 1.0 / r
        
        quat.x *= invr
        quat.y *= invr
        quat.z *= invr
        quat.w *= invr
    }
    
    #if os(macOS)
    internal func createTexture(fileName: String, light: OSColor) -> NSImage? {
        guard let image = NSImage(contentsOfFile: fileName) else { return nil }
        return createTexture(image, light: light)
    }
    
    internal func createTexture(_ texture: NSImage, light: OSColor) -> NSImage? {
        var rect = NSRect(x: 0, y: 0, width: texture.size.width, height: texture.size.height)
        guard let cgImage = texture.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return texture }
        
        guard let newCGImage = self.createTexture(cgImage: cgImage, light: light) else { return texture }
        
        return NSImage(cgImage: newCGImage, size: texture.size)
    }
    
    internal func getColorComponents(color: OSColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        return (color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent)
    }
    #else
    internal func createTexture(fileName: String, light: OSColor) -> CGImage? {
        guard let image = UIImage(contentsOfFile: fileName) else { return nil }
        return createTexture(image, light: light)
    }
    
    internal func createTexture(_ texture: UIImage, light: OSColor) -> CGImage? {
        guard let cgImage = texture.cgImage else { return nil }
        
        return self.createTexture(cgImage: cgImage, light: light)
    }
    
    internal func getColorComponents(color: OSColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return (r, g, b, a)
    }
    #endif
    
    
    #if os(watchOS)
    internal func createTexture(cgImage: CGImage, light: OSColor) -> CGImage? {
        return cgImage
    }
    #else
    internal func createTexture(cgImage: CGImage, light: OSColor) -> CGImage? {
        //guard let cgImage = texture.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        return cgImage
        
        guard let filter = CIFilter(name: "CIColorPolynomial") else { return cgImage }
        
        var lightRed: CGFloat
        var lightGreen: CGFloat
        var lightBlue: CGFloat
        var lightAlpha: CGFloat
        (lightRed, lightGreen, lightBlue, lightAlpha) = self.getColorComponents(color: light)
        
        let red = CIVector(x: 0.0, y: lightRed, z: 0.0, w: 0.0)
        let green = CIVector(x: 0.0, y: lightGreen, z: 0.0, w: 0.0)
        let blue = CIVector(x: 0.0, y: lightBlue, z: 0.0, w: 0.0)
        //let alpha = CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0.0)
        print("light: \(lightRed), \(lightGreen), \(lightBlue)")
        
        filter.setValue(ciImage, forKey: "inputImage")
        filter.setValue(red, forKey: "inputRedCoefficients")
        filter.setValue(green, forKey: "inputGreenCoefficients")
        filter.setValue(blue, forKey: "inputBlueCoefficients")
        //filter.setValue(alpha, forKey: "inputAlphaCoefficients")
        
        guard let newImage = filter.outputImage else { return cgImage }
        
        return newImage.cgImage
    }
    #endif
    
    #if !os(watchOS)
    /**
     * create new CAKeyframeAnimation object with initializing values, keyTimes, timingFunctions
     * - parameter keyPath: key path for the animation
     * - parameter usesTimingFunctions: if it's true, timingFunctions will be initialized
     */
    internal func createKeyframeAnimation(keyPath: String, usesTimingFunctions: Bool) {
        let motion = CAKeyframeAnimation(keyPath: keyPath)
        
        motion.values = [AnyObject]()
        motion.keyTimes = [NSNumber]()
        
        if usesTimingFunctions {
            motion.timingFunctions = [CAMediaTimingFunction]()
        }
    }
    
    /**
     * normalize CAKeyframeAnimation.keyTimes to [0, 1]
     * - parameter animations: an array of CAKeyframeAnimation to normalize
     */
    internal func normalizeKeytimes(animations: [CAKeyframeAnimation], fps: Double = 30.0) {
        for motion in animations {
            let motionLength = motion.keyTimes!.last!.doubleValue
            motion.duration = motionLength / fps
            motion.usesSceneTimeBase = false
            motion.isRemovedOnCompletion = false
            motion.fillMode = kCAFillModeForwards
            
            for num in 0..<motion.keyTimes!.count {
                let keyTime = motion.keyTimes![num].floatValue / Float(motionLength)
                motion.keyTimes![num] = NSNumber(value: keyTime)
            }
        }
    }
    #endif
    // for debug
    var _pos: Int {
        get {
            return self.pos
        }
    }
}
