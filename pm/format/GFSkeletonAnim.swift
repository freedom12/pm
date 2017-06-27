//
//  GFSkeletonAnim.swift
//  pm
//
//  Created by wanghuai on 2017/6/26.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFSkeletonAnim {
    var file:FileHandle
    var frameCount:Int = 0
    var transforms:[GFSkeletonBoneTransform] = []
    init( withFile _file:FileHandle, frameCount _frameCount:Int ) {
        file = _file
        frameCount = _frameCount
        
        let boneNameCount = file.readInt32()
        let boneNameLen = file.readInt32()
        let pos = file.pos
        
        var boneNames:[String] = []
        for _ in 0 ..< boneNameCount {
            boneNames.append(file.readString(len: file.readInt8()))
        }
        
        file.seek(to: pos + boneNameLen)
        print(file.pos)
        for name in boneNames {
            let transform = GFSkeletonBoneTransform.init(withFile: file, frameCount: frameCount)
            transform.name = name
            transforms.append(transform)
        }
    }
}

class GFSkeletonBoneTransform {
    var file:FileHandle
    var frameCount:Int = 0
    var name = ""
    var isAxisAngle = false
    
    var scaleXFrames:[GFKeyFrame] = []
    var scaleYFrames:[GFKeyFrame] = []
    var scaleZFrames:[GFKeyFrame] = []
    
    var rotationXFrames:[GFKeyFrame] = []
    var rotationYFrames:[GFKeyFrame] = []
    var rotationZFrames:[GFKeyFrame] = []
    
    var translationXFrames:[GFKeyFrame] = []
    var translationYFrames:[GFKeyFrame] = []
    var translationZFrames:[GFKeyFrame] = []
    
    init( withFile _file:FileHandle, frameCount _frameCount:Int ) {
        file = _file
        frameCount = _frameCount
        
        let flag = file.readUInt32()
        _ = file.readUInt32()
        
        isAxisAngle = (flag >> 31) == 0
        
        scaleXFrames = readFrames(flag: (flag >> 0))
        scaleYFrames = readFrames(flag: (flag >> 3))
        scaleZFrames = readFrames(flag: (flag >> 6))
        rotationXFrames = readFrames(flag: (flag >> 9))
        rotationYFrames = readFrames(flag: (flag >> 12))
        rotationZFrames = readFrames(flag: (flag >> 15))
        translationXFrames = readFrames(flag: (flag >> 18))
        translationYFrames = readFrames(flag: (flag >> 21))
        translationZFrames = readFrames(flag: (flag >> 24))
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

struct GFKeyFrame {
    var frame = 0
    var value:Float = 0
    var slope:Float = 0
}
