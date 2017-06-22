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
        data = decode(data: gfTexture.rawBuffer)
        
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Uint, width: width, height: height, mipmapped: false)
        texture = device.makeTexture(descriptor: desc)
        texture.replace(region: MTLRegionMake2D(0, 0, width, height),
                        mipmapLevel: 0, slice: 0, withBytes: data.bytes,
                        bytesPerRow: 4 * width, bytesPerImage: 4 * width * height)
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
    
    private func decode(data:NSData) -> NSData {
        let inBuffer = data.bytes.assumingMemoryBound(to: UInt8.self)
        let outBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: width*height*4)
        
        let inc = 32 / 8
        var ioffs = 0
        
        for ty in 0 ..< height/8 {
            for tx in 0 ..< width/8 {
                for p in 0 ..< 64 {
                    let x = Texture.swizzleLUT[p] & 7
                    let y = (Texture.swizzleLUT[p] - x) >> 3
                    
                    let ooffs = (tx*8 + x + ((height - 1 - (ty*8 + y)) * width)) * 4
                    
                    outBuffer[ooffs + 0] = inBuffer[ioffs + 3]
                    outBuffer[ooffs + 1] = inBuffer[ioffs + 2]
                    outBuffer[ooffs + 2] = inBuffer[ioffs + 1]
                    outBuffer[ooffs + 3] = inBuffer[ioffs + 0]
                    ioffs += inc
                }
            }
        }
        
        let ret = NSData.init(bytes: outBuffer, length: width*height*4)
        outBuffer.deallocate(capacity: width*height*4)
        return ret
    }
}
