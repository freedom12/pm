//
//  GFMaterialAnim.swift
//  pm
//
//  Created by wanghuai on 2017/6/26.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFMaterialAnim {
    var file:FileHandle
    var frameCount:Int = 0
    var transforms:[GFMaterialUVTransform] = []
    init( withFile _file:FileHandle, frameCount _frameCount:Int ) {
        file = _file
        frameCount = _frameCount
        
        let materialNameCount = file.readInt32()
        let materialNameLen = file.readUInt32()
        
        var units:[Int] = []
        for _ in 0 ..< materialNameCount {
            units.append(file.readUInt32())
        }
        
        let pos = file.pos
        
        var materialNames:[String] = []
        for _ in 0 ..< materialNameCount {
            materialNames.append(file.readString(len: file.readInt8()))
        }
        
        file.seek(to: pos + materialNameLen)
        
        for i in 0 ..< materialNames.count {
            for _ in 0 ..< units[i] {
                let transform = GFMaterialUVTransform.init(withFile: file, frameCount: frameCount)
                transform.name = materialNames[i]
                transforms.append(transform)
            }
        }
    }
}

class GFMaterialUVTransform {
    var file:FileHandle
    var frameCount:Int = 0
    var name = ""
    
    var unitIndex = 0
    
    var scaleXFrames:[GFKeyFrame] = []
    var scaleYFrames:[GFKeyFrame] = []
    var rotationFrames:[GFKeyFrame] = []
    var translationXFrames:[GFKeyFrame] = []
    var translationYFrames:[GFKeyFrame] = []
    
    init( withFile _file:FileHandle, frameCount _frameCount:Int ) {
        file = _file
        frameCount = _frameCount
        unitIndex = file.readUInt32()
        
        let flag = file.readUInt32()
        _ = file.readUInt32()
        
        scaleXFrames = readFrames(flag: (flag >> 0))
        scaleYFrames = readFrames(flag: (flag >> 3))
        rotationFrames = readFrames(flag: (flag >> 6))
        translationXFrames = readFrames(flag: (flag >> 9))
        translationYFrames = readFrames(flag: (flag >> 12))
    }
    
    private func readFrames(flag:Int) -> [GFKeyFrame] {
        var keyFrames:[GFKeyFrame] = []
        switch(flag & 7) {
        case 3:
            let frame = GFKeyFrame(frame: 0, value: file.readSingle(), slope: 0)
            keyFrames.append(frame)
        case 4: fallthrough
        case 5:
            let keyFrameCount = file.readUInt32()
            var frames:[Int] = []
            for _ in 0 ..< keyFrameCount {
                if frameCount > 0xff {
                    frames.append(file.readUInt16())
                } else {
                    frames.append(file.readInt8())
                }
            }
            
            while (file.pos & 3) != 0 {
                _ = file.readInt8()
            }
            
            if (flag & 1) != 0 {
                for i in 0 ..< keyFrameCount {
                    let frame = GFKeyFrame(frame: frames[i], value: file.readSingle(), slope: file.readSingle())
                    keyFrames.append(frame)
                }
            } else {
                let valueScale = file.readSingle()
                let valueOffset = file.readSingle()
                let slopeScale = file.readSingle()
                let slopeOffset = file.readSingle()
                
                for i in 0 ..< keyFrameCount {
                    let value = Float(file.readUInt16()) / 0xffff * valueScale + valueOffset
                    let slope = Float(file.readUInt16()) / 0xffff * slopeScale + slopeOffset
                    let frame = GFKeyFrame(frame: frames[i], value: value, slope: slope)
                    keyFrames.append(frame)
                }
            }
        default:break
        }
        
        return keyFrames
    }
}
