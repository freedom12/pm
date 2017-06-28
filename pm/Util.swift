//
//  Util.swift
//  pm
//
//  Created by wanghuai on 2017/6/19.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class Util {
    static func float24ToVect4(words:[Int]) -> Vector4 {
        let x = getFloat24(value: words[2] & 0xffffff)
        let y = getFloat24(value: (words[2] >> 24) | ((words[1] & 0xffffff) << 8))
        let z = getFloat24(value: (words[1] >> 16) | ((words[0] & 0xff) << 16))
        let w = getFloat24(value: words[0] >> 8)
        
        return Vector4.init(x, y, z, w)
    }
    
    static private func getFloat24( value:Int ) -> Float {
        var tmpValue = 0
        if ((value & 0x7fffff) != 0) {
            let mantissa = value & 0xffff
            let exponent = ((value >> 16) & 0x7f) + 64
            let signBit = (value >> 23) & 1
            
            tmpValue = mantissa << 7
            tmpValue = tmpValue | (exponent << 23)
            tmpValue = tmpValue | (signBit << 31)
        } else {
            tmpValue = (value & 0x800000) << 8
        }
        
        var tmp = UInt32(tmpValue)
        let data = NSData.init(bytes: &tmp, length: 4)
        var ret:Float = 0
        data.getBytes(&ret, length: 4)
        
        return ret
    }
}
