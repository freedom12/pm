//
//  GFTexture.swift
//  pm
//
//  Created by wanghuai on 2017/6/21.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFTexture {
    var file:FileHandle
    var name = ""
    
    var width = 0
    var height = 0
    var format:GFTextureFormat = .RGB565
    var mipmapSize = 0
    
    var rawBuffer:NSData = NSData.init()
    
    init( withFile _file:FileHandle ) {
        file = _file
        
        let length = file.readUInt32()
        file.seek(by: 0xc)
        name = file.readString(len: 0x40)
        
        width = file.readInt16()
        height = file.readInt16()
        let tmp = file.readInt16()
        format = GFTextureFormat.init(rawValue: tmp)!
        mipmapSize = file.readInt16()
        
        file.seek(by: 0x10)
        rawBuffer = NSData.init(data: file.readData(ofLength: length))
    }
}

enum GFTextureFormat:Int {
    case RGB565 = 0x2
    case RGB8 = 0x3
    case RGBA8 = 0x4
    case RGBA4 = 0x16
    case RGBA5551 = 0x17
    case LA8 = 0x23
    case HiLo8 = 0x24
    case L8 = 0x25
    case A8 = 0x26
    case LA4 = 0x27
    case L4 = 0x28
    case A4 = 0x29
    case ETC1 = 0x2a
    case ETC1A4 = 0x2b
}
