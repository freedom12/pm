//
//  GFVisibilityAnim.swift
//  pm
//
//  Created by wanghuai on 2017/6/26.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFVisibilityAnim {
    var file:FileHandle
    var frameCount:Int = 0
    var visibilities:[GFVisibilityBoolean] = []
    init( withFile _file:FileHandle, frameCount _frameCount:Int ) {
        file = _file
        frameCount = _frameCount
        
        let meshNameCount = file.readInt32()
        let meshNameLen = file.readUInt32()
        
        let pos = file.pos
        
        var meshNames:[String] = []
        for _ in 0 ..< meshNameCount {
            meshNames.append(file.readString(len: file.readInt8()))
        }
        
        file.seek(to: pos + meshNameLen)
        
        for name in meshNames {
            let visibility = GFVisibilityBoolean.init(withFile: file, frameCount: frameCount+1)
            visibility.name = name
            visibilities.append(visibility)
        }
    }
}

class GFVisibilityBoolean {
    var file:FileHandle
    var frameCount:Int = 0
    var name = ""
    var values:[Bool] = []
    init( withFile _file:FileHandle, frameCount _frameCount:Int ) {
        file = _file
        frameCount = _frameCount
        
        var value = 0
        for i in 0 ..< frameCount {
            let bit = i & 7
            if bit == 0 {
               value = file.readUInt8()
            }
            values.append((value & (1 << bit)) != 0)
        }
    }
}
