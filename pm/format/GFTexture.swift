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
        format = GFTextureFormat(rawValue: tmp)!
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
    
    func to() -> PICATextureFormate {
        switch self {
        case .RGB565: return PICATextureFormate.RGB565
        case .RGB8: return PICATextureFormate.RGB8
        case .RGBA8: return PICATextureFormate.RGBA8
        case .RGBA4: return PICATextureFormate.RGBA4
        case .RGBA5551: return PICATextureFormate.RGBA5551
        case .LA8: return PICATextureFormate.LA8
        case .HiLo8: return PICATextureFormate.HiLo8
        case .L8: return PICATextureFormate.L8
        case .A8: return PICATextureFormate.A8
        case .LA4: return PICATextureFormate.LA4
        case .L4: return PICATextureFormate.L4
        case .A4: return PICATextureFormate.A4
        case .ETC1: return PICATextureFormate.ETC1
        case .ETC1A4: return PICATextureFormate.ETC1A4
        }
    }
}
