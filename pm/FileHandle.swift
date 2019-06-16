//
//  FileHandle.swift
//  pm
//
//  Created by wanghuai on 2017/6/14.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

extension Data {
    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }
    
    func to<T>(type: T.Type) -> T? where T: ExpressibleByIntegerLiteral {
        var value: T = 0
        guard count >= MemoryLayout.size(ofValue: value) else { return nil }
        _ = Swift.withUnsafeMutableBytes(of: &value, { copyBytes(to: $0)} )
        return value
    }
}

public extension FileHandle {
    func length() -> Int {
        let position = self.offsetInFile
        self.seekToEndOfFile()
        let len = self.offsetInFile
        self.seek(toFileOffset: position)
        return Int(len)
    }
    
    func readUInt64() -> Int {
        let len = 8
        let data = self.readData(ofLength: len)
        if let val = data.to(type: UInt64.self) {
            return Int(val)
        } else {
            print("not enough data")
            return 0
        }
    }
    
    func readUInt32() -> Int {
        let len = 4
        let data = self.readData(ofLength: len)
        if let val = data.to(type: UInt32.self) {
            return Int(val)
        } else {
            print("not enough data")
            return 0
        }
    }
    
    func readUInt16() -> Int {
        let len = 2
        let data = self.readData(ofLength: len)
        if let val = data.to(type: UInt16.self) {
            return Int(val)
        } else {
            print("not enough data")
            return 0
        }
    }
    
    func readUInt8() -> Int {
        let len = 1
        let data = self.readData(ofLength: len)
        if let val = data.to(type: UInt8.self) {
            return Int(val)
        } else {
            print("not enough data")
            return 0
        }
    }
    
    func readInt64() -> Int {
        let len = 8
        let data = self.readData(ofLength: len)
        if let val = data.to(type: Int64.self) {
            return Int(val)
        } else {
            print("not enough data")
            return 0
        }
    }
    
    func readInt32() -> Int {
        let len = 4
        let data = self.readData(ofLength: len)
        if let val = data.to(type: Int32.self) {
            return Int(val)
        } else {
            print("not enough data")
            return 0
        }
    }
    
    func readInt16() -> Int {
        let len = 2
        let data = self.readData(ofLength: len)
        if let val = data.to(type: Int16.self) {
            return Int(val)
        } else {
            print("not enough data")
            return 0
        }
    }
    
    func readInt8() -> Int {
        let len = 1
        let data = self.readData(ofLength: len)
        if let val = data.to(type: Int8.self) {
            return Int(val)
        } else {
            print("not enough data")
            return 0
        }    }
    
    
    func readString(len:Int) -> String {
        let data = self.readData(ofLength: len)
        var str = String.init(data: data, encoding: String.Encoding.ascii)!
        str = str.replacingOccurrences(of: "\0", with: "")
        return str
    }
    
    func readStringByte() -> String {
        let len = readUInt8()
        return readString(len: len)
    }
        
    func readByte() -> Data {
        let data = self.readData(ofLength: 1)
        return data
    }
    
    func readSByte() -> Data {
        let data = self.readData(ofLength: 1)
        return data
    }
    
    
    func skipPadding() {
        while ((self.offsetInFile & 0xf) != 0) {
            _ = self.readByte()
        }
    }
    
    var pos:Int {
        get {
            return Int(self.offsetInFile)
        }
    }
    
    func seek(to pos:Int) {
        self.seek(toFileOffset: UInt64(pos))
    }
    
    func seek(by pos:Int) {
        self.seek(to: self.pos + pos)
    }
    
    func readSingle() -> Float {
        let len = 4
//        let data = NSData.init(data: self.readData(ofLength: len))
//        var val:Float = 0
//        data.getBytes(&val, length: len)
        let data = self.readData(ofLength: len)
        if let val = data.to(type: Float.self) {
            return val
        } else {
            print("not enough data")
            return 0
        }
    }
    
    func readVector2() -> Vector2 {
        return Vector2.init(readSingle(), readSingle())
    }
    
    func readVector3() -> Vector3 {
        return Vector3.init(readSingle(), readSingle(), readSingle())
    }
    
    func readVector4() -> Vector4 {
        return Vector4.init(readSingle(), readSingle(), readSingle(), readSingle())
    }
    
    func readMatrix3() -> Matrix3 {
        return Matrix3.init(
            readSingle(), readSingle(), readSingle(),
            readSingle(), readSingle(), readSingle(),
            readSingle(), readSingle(), readSingle()
        )
    }
    
    func readMatrix4() -> Matrix4 {
        return Matrix4.init(
            readSingle(), readSingle(), readSingle(), readSingle(),
            readSingle(), readSingle(), readSingle(), readSingle(),
            readSingle(), readSingle(), readSingle(), readSingle(),
            readSingle(), readSingle(), readSingle(), readSingle()
        )
    }
    
}
