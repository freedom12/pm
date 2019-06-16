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
    var model:GFModelContainer?
    var modelLow:GFModelContainer?
    var textures:[GFTexture] = []
    var anims:[GFAnim] = []
    var fragShaders:[GFFragShader] = []
    
    let GFModelConstant:Int = 0x15122117
    let GFTextureConstant:Int = 0x15041213
    let GFMotionConstant:Int = 0x00060000
    let GFResourceConstant:Int = 0x00010000 //todo
    let BCHConstant:Int = 0x00484342
    let GFFragShaderConstant:Int = 217936
    
    init() {
        model = nil
        textures = []
        fragShaders = []
    }
    
    public func merg(withFile file:FileHandle) {
        file.seek(to: 0)
        
        _ = file.readString(len: 2)//magic
        let count = file.readUInt16()
        
        var offsets:[Int] = []
        for _ in 0...count {
            offsets.append(file.readUInt32())
        }
        
        var entries:[Entry] = []
        for i in 0...(count-1) {
            var entry = Entry()
            entry.addr = offsets[i]
            entry.len = offsets[i+1] - offsets[i]
            entries.append(entry)
        }
        
        for i in 0 ..< count {
            file.seek(to: entries[i].addr)
            let magicNum = file.readUInt32()
            file.seek(to: entries[i].addr)
            
            switch magicNum {
            case GFModelConstant:
                if i == 0 {
                    model = GFModelContainer.init(withFile: file)
                } else if i == 1 {
                    modelLow = GFModelContainer.init(withFile: file)
                }
            case GFFragShaderConstant:
                _ = file.readString(len: 2)//magic
                let fragShaderEntryCount = file.readUInt16()
                var fragShaderEntries:[Entry] = []
                let pos = file.pos
                for i in 0...(fragShaderEntryCount-1) {
                    file.seek(to: (pos + i * 4))
                    let startAddr = file.readUInt32()
                    let endAddr = file.readUInt32()
                    
                    var entry = Entry()
                    entry.addr = pos - 4 + startAddr
                    entry.len = endAddr - startAddr
                    fragShaderEntries.append(entry)
                }
                for j in 0 ..< fragShaderEntryCount {
                    file.seek(to: fragShaderEntries[j].addr)
                    let containter = GFFragShaderContainer.init(withFile: file)
                    for fragShader in containter.fragShaders {
                        fragShaders.append(fragShader)
                    }
                }
                
            case GFTextureConstant:
                let container = GFTextureContainer.init(withFile: file)
                for texture in container.textures {
                    textures.append(texture)
                }
            case GFMotionConstant:
                let container = GFAnimContainer.init(withFile: file)
                var anim = GFAnim()
                anim.frameCount = container.frameCount
                anim.isLoop = container.isLoop
                anim.skeletonAnim = container.skeletonAnim
                anim.materialAnim = container.materialAnim
                anim.visibilityAnim = container.visibilityAnim
                anims.append(anim)
            default: break
            }
        }
    }
}

struct GFAnim {
    var skeletonAnim:GFSkeletonAnim? = nil
    var materialAnim:GFMaterialAnim? = nil
    var visibilityAnim:GFVisibilityAnim? = nil
    var name = ""
    var frameCount = 0
    var isLoop = false
}
