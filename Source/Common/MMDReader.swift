//
//  MMDReader.swift
//  MMDSceneKit
//
//  Created by magicien on 12/17/15.
//  Copyright © 2015 DarkHorse. All rights reserved.
//

import SceneKit

internal class MMDReader: NSObject {
    internal var directoryPath: String! = ""
    internal var binaryData: Data! = nil
    internal var length = 0
    internal var pos = 0
    
    /**
     * 
     * - parameter data: 
     * - parameter directoryPath:
     */
    internal init(data: Data!, directoryPath: String! = "") {
        self.directoryPath = directoryPath
        self.binaryData = data
        self.length = data.count
        self.pos = 0
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
        self.binaryData.copyBytes(to: pointer, from: Range(self.pos..<self.pos+2))

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
        self.binaryData.copyBytes(to: pointer, from: Range(self.pos..<self.pos+4))
        
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
        self.binaryData.copyBytes(to: pointer, from: Range(self.pos..<self.pos+4))

        self.pos += 4
        
        return num
    }
    
    /**
     * read Int data and return Int value from file
     * - returns: Signed Int data
     */
    internal func getIntOfLength(_ length: Int) -> Int {
        var num: Int = 0
        
        if length <= 0 || length > 4 {
            return 0
        }
        
        //let token = self.binaryData.subdata(in: NSRange.init(location: self.pos, length: length))
        //token.copyBytes(to: &num, count: length)
        let pointer = UnsafeMutableBufferPointer<Int>(start: &num, count: 1)
        self.binaryData.copyBytes(to: pointer, from: Range(self.pos..<self.pos+length))

        self.pos += length
        
        return num
    }
    
    /**
     * read Float32 data and return Int value from file
     * - returns: Float data
     */
    internal func getFloat() -> Float32 {
        var num: Float32 = 0
        //let token = self.binaryData.subdata(in: Range(self.pos..<self.pos+4))
        //token.copyBytes(to: &num, from: Range(0..<4))

        let pointer = UnsafeMutableBufferPointer<Float32>(start: &num, count: 1)
        self.binaryData.copyBytes(to: pointer, from: Range(self.pos..<self.pos+4))

        self.pos += 4
        
        return num
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
}
