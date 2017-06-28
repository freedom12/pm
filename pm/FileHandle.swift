//
//  FileHandle.swift
//  pm
//
//  Created by wanghuai on 2017/6/14.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

public extension FileHandle {
    public func length() -> Int {
        let position = self.offsetInFile
        self.seekToEndOfFile()
        let len = self.offsetInFile
        self.seek(toFileOffset: position)
        return Int(len)
    }
    
    public func readUInt64() -> Int {
        let len = 8
        let data = NSData.init(data: self.readData(ofLength: len))
        var val:UInt64 = 0
        data.getBytes(&val, length: len)
        return Int(val)
    }
    
    public func readUInt32() -> Int {
        let len = 4
        let data = NSData.init(data: self.readData(ofLength: len))
        var val:UInt32 = 0
        data.getBytes(&val, length: len)
        return Int(val)
    }
    
    public func readUInt16() -> Int {
        let len = 2
        let data = NSData.init(data: self.readData(ofLength: len))
        var val:UInt16 = 0
        data.getBytes(&val, length: len)
        return Int(val)
    }
    
    public func readUInt8() -> Int {
        let len = 1
        let data = NSData.init(data: self.readData(ofLength: len))
        var val:UInt8 = 0
        data.getBytes(&val, length: len)
        return Int(val)
    }
    
    public func readInt64() -> Int {
        let len = 8
        let data = NSData.init(data: self.readData(ofLength: len))
        var val:Int64 = 0
        data.getBytes(&val, length: len)
        return Int(val)
    }
    
    public func readInt32() -> Int {
        let len = 4
        let data = NSData.init(data: self.readData(ofLength: len))
        var val:Int32 = 0
        data.getBytes(&val, length: len)
        return Int(val)
    }
    
    public func readInt16() -> Int {
        let len = 2
        let data = NSData.init(data: self.readData(ofLength: len))
        var val:Int16 = 0
        data.getBytes(&val, length: len)
        return Int(val)
    }
    
    public func readInt8() -> Int {
        let len = 1
        let data = NSData.init(data: self.readData(ofLength: len))
        var val:Int8 = 0
        data.getBytes(&val, length: len)
        return Int(val)
    }
    
    
    public func readString(len:Int) -> String {
        let data = self.readData(ofLength: len)
        var str = String.init(data: data, encoding: String.Encoding.ascii)!
        str = str.replacingOccurrences(of: "\0", with: "")
        return str
    }
    
    public func readStringByte() -> String {
        let len = readUInt8()
        return readString(len: len)
    }
        
    public func readByte() -> Data {
        let data = self.readData(ofLength: 1)
        return data
    }
    
    public func readSByte() -> Data {
        let data = self.readData(ofLength: 1)
        return data
    }
    
    
    public func skipPadding() {
        while ((self.offsetInFile & 0xf) != 0) {
            _ = self.readByte()
        }
    }
    
    var pos:Int {
        get {
            return Int(self.offsetInFile)
        }
    }
    
    public func seek(to pos:Int) {
        self.seek(toFileOffset: UInt64(pos))
    }
    
    public func seek(by pos:Int) {
        self.seek(to: self.pos + pos)
    }
    
    public func readSingle() -> Float {
        let len = 4
        let data = NSData.init(data: self.readData(ofLength: len))
        var val:Float = 0
        data.getBytes(&val, length: len)
        return val
    }
    
    public func readVector2() -> Vector2 {
        return Vector2.init(readSingle(), readSingle())
    }
    
    public func readVector3() -> Vector3 {
        return Vector3.init(readSingle(), readSingle(), readSingle())
    }
    
    public func readVector4() -> Vector4 {
        return Vector4.init(readSingle(), readSingle(), readSingle(), readSingle())
    }
    
    public func readMatrix3() -> Matrix3 {
        return Matrix3.init(
            readSingle(), readSingle(), readSingle(),
            readSingle(), readSingle(), readSingle(),
            readSingle(), readSingle(), readSingle()
        )
    }
    
    public func readMatrix4() -> Matrix4 {
        return Matrix4.init(
            readSingle(), readSingle(), readSingle(), readSingle(),
            readSingle(), readSingle(), readSingle(), readSingle(),
            readSingle(), readSingle(), readSingle(), readSingle(),
            readSingle(), readSingle(), readSingle(), readSingle()
        )
    }
    
}
