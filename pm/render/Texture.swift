//
//  Texture.swift
//  pm
//
//  Created by wanghuai on 2017/6/21.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
import  Metal
class Texture {
    var device:MTLDevice! = nil
    
    var name = ""
    var width = 0
    var height = 0
    
    var texture:MTLTexture! = nil
    var data:NSData = NSData.init()
    init(device _device:MTLDevice, gfTexture:GFTexture){
        device = _device
        
        name = gfTexture.name
        width = gfTexture.width
        height = gfTexture.height
        data = decode(data: gfTexture.rawBuffer, formate: gfTexture.format)
        
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Uint, width: width, height: height, mipmapped: false)
        texture = device.makeTexture(descriptor: desc)
        texture.replace(region: MTLRegionMake2D(0, 0, width, height),
                        mipmapLevel: 0, slice: 0, withBytes: data.bytes,
                        bytesPerRow: 4 * width, bytesPerImage: 4 * width * height)
        texture.label = name
    }
    
    private static let swizzleLUT:[Int] = [
         0,  1,  8,  9,  2,  3, 10, 11,
        16, 17, 24, 25, 18, 19, 26, 27,
         4,  5, 12, 13,  6,  7, 14, 15,
        20, 21, 28, 29, 22, 23, 30, 31,
        32, 33, 40, 41, 34, 35, 42, 43,
        48, 49, 56, 57, 50, 51, 58, 59,
        36, 37, 44, 45, 38, 39, 46, 47,
        52, 53, 60, 61, 54, 55, 62, 63
    ]
    private static let formateBPP:[Int] = [
        32, 24, 16, 16, 16, 16, 16, 8, 8, 8, 4, 4, 4, 8
    ]
    
    private func decode(data:NSData, formate:GFTextureFormat) -> NSData {
        let inBuffer = data.bytes.assumingMemoryBound(to: UInt8.self)
        let outBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: width*height*4)
        
        var inc = Texture.formateBPP[formate.to().rawValue] / 8
        if inc == 0 {
            inc = 1
        }
        var ioffs = 0
        
        for ty in 0 ..< height/8 {
            for tx in 0 ..< width/8 {
                for p in 0 ..< 64 {
                    let x = Texture.swizzleLUT[p] & 7
                    let y = (Texture.swizzleLUT[p] - x) >> 3
                    
                    let ooffs = (tx*8 + x + ((height - 1 - (ty*8 + y)) * width)) * 4
                    
                    switch formate.to() {
                    case .RGBA8:
                        outBuffer[ooffs + 0] = inBuffer[ioffs + 3]
                        outBuffer[ooffs + 1] = inBuffer[ioffs + 2]
                        outBuffer[ooffs + 2] = inBuffer[ioffs + 1]
                        outBuffer[ooffs + 3] = inBuffer[ioffs + 0]
                    case .RGB8:
                        outBuffer[ooffs + 0] = inBuffer[ioffs + 2]
                        outBuffer[ooffs + 1] = inBuffer[ioffs + 1]
                        outBuffer[ooffs + 2] = inBuffer[ioffs + 0]
                        outBuffer[ooffs + 3] = 0xff
                    case .RGB565:
                        let value = (UInt16(inBuffer[ioffs + 0]) << 0) | (UInt16(inBuffer[ioffs + 1]) << 8)
                        let r = ((value >> 0) & 0x1f) << 3
                        let g = ((value >> 5) & 0x3f) << 2
                        let b = ((value >> 11) & 0x1f) << 3
                        outBuffer[ooffs + 0] = UInt8(b | (b >> 5))
                        outBuffer[ooffs + 1] = UInt8(g | (g >> 6))
                        outBuffer[ooffs + 2] = UInt8(r | (r >> 5))
                        outBuffer[ooffs + 3] = 0xff
                    case .RGBA4:
                        let value = (UInt16(inBuffer[ioffs + 0]) << 0) | (UInt16(inBuffer[ioffs + 1]) << 8)
                        let a = (value >> 0) & 0xf
                        let r = (value >> 4) & 0xf
                        let g = (value >> 8) & 0xf
                        let b = (value >> 12) & 0xf
                        outBuffer[ooffs + 0] = UInt8(b | (b << 4))
                        outBuffer[ooffs + 1] = UInt8(g | (g << 4))
                        outBuffer[ooffs + 2] = UInt8(r | (r << 4))
                        outBuffer[ooffs + 3] = UInt8(a | (a << 4))
                    case .L4:
                        let l = Int(inBuffer[ioffs >> 1] >> ((ioffs & 1) << 2)) & 0xf
                        outBuffer[ooffs + 0] = UInt8((l << 4) | l)
                        outBuffer[ooffs + 1] = UInt8((l << 4) | l)
                        outBuffer[ooffs + 2] = UInt8((l << 4) | l)
                        outBuffer[ooffs + 3] = UInt8(0xff)
                    case .LA4:
                        outBuffer[ooffs + 0] = UInt8((inBuffer[ioffs] >> 4) | (inBuffer[ioffs] & 0xf0));
                        outBuffer[ooffs + 1] = UInt8((inBuffer[ioffs] >> 4) | (inBuffer[ioffs] & 0xf0));
                        outBuffer[ooffs + 2] = UInt8((inBuffer[ioffs] >> 4) | (inBuffer[ioffs] & 0xf0));
                        outBuffer[ooffs + 3] = UInt8((inBuffer[ioffs] >> 4) | (inBuffer[ioffs] & 0x0f));
                    case .L8:
                        outBuffer[ooffs + 0] = inBuffer[ioffs]
                        outBuffer[ooffs + 1] = inBuffer[ioffs]
                        outBuffer[ooffs + 2] = inBuffer[ioffs]
                        outBuffer[ooffs + 3] = UInt8(0xff)
                    case .LA8:
                        outBuffer[ooffs + 0] = inBuffer[ioffs + 1]
                        outBuffer[ooffs + 1] = inBuffer[ioffs + 1]
                        outBuffer[ooffs + 2] = inBuffer[ioffs + 1]
                        outBuffer[ooffs + 3] = inBuffer[ioffs]
                    default: print(name, formate)
                    }
                    
                    ioffs += inc
                }
            }
        }
        
        let ret = NSData.init(bytes: outBuffer, length: width*height*4)
        outBuffer.deallocate(capacity: width*height*4)
        return ret
    }
}
