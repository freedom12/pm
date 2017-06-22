//
//  GFPackage.swift
//  pm
//
//  Created by wanghuai on 2017/6/14.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

struct Entry {
    var addr = 0
    var len = 0
}

class GFPackage {
//    var file:FileHandle
//    var magic:String = ""
//    var entries:[Entry] = []
//    var containters:[GFContainer] = []
    var model:GFModelContainter? = nil
    var textures:[GFTexture] = []
    
    
    let GFModelConstant:Int = 0x15122117
    let GFTextureConstant:Int = 0x15041213
    let GFMotionConstant:Int = 0x00060000
    let BCHConstant:Int = 0x00484342
    
    init() {
        model = nil
        textures = []
    }
    
    public func merg(withFile file:FileHandle) {
        file.seek(toFileOffset: 0)
        
        let magic = file.readString(len: 2)
        let entryCount = file.readUInt16()
        var entries:[Entry] = []
        let pos = Int(file.offsetInFile)
        for i in 0...(entryCount-1) {
            file.seek(toFileOffset: UInt64(pos + i * 4))
            let startAddr = file.readUInt32()
            let endAddr = file.readUInt32()
            
            var entry = Entry()
            entry.addr = pos - 4 + startAddr
            entry.len = endAddr - startAddr
            entries.append(entry)
        }
        
        for i in 0 ..< entryCount {
            file.seek(to: entries[i].addr)
            let magicNum = file.readUInt32()
            file.seek(to: entries[i].addr)
            switch magicNum {
            case GFModelConstant:
                if i == 0 {
                    model = GFModelContainter.init(withFile: file)
                }
            case GFTextureConstant:
                let containter = GFTextureContainter.init(withFile: file)
                for texture in containter.textures {
                    textures.append(texture)
                }
            default: break
            }
        }
    }
}
