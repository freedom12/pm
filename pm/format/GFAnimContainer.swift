//
//  GFAnimContainter.swift
//  pm
//
//  Created by wanghuai on 2017/6/26.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFAnimContainer:GFContainer {
    var sections:[Section] = []
    var frameCount = 0
    var isLoop = false
    var isBlend = false
    var regionMin = Vector3.init(0, 0, 0)
    var regionMax = Vector3.init(0, 0, 0)
    
    var skeletonAnim:GFSkeletonAnim? = nil
    var materialAnim:GFMaterialAnim? = nil
    var visibilityAnim:GFVisibilityAnim? = nil
    override init( withFile _file:FileHandle ) {
        let pos = _file.pos
        
        super.init(withFile: _file)
        
        let sectionCount = file.readUInt32()
        
        sections = []
        for _ in 0 ..< sectionCount {
            var section = Section()
            section.magic = String(file.readUInt32())
            section.len = file.readUInt32()
            section.addr = file.readUInt32() + pos
            sections.append(section)
//            file.seek(by: section.len)
        }
        
        for section in sections {
            file.seek(to: section.addr)
            switch section.magic {
            case "0":
                frameCount = file.readUInt32()
                isLoop = (file.readUInt16() & 1) != 0
                isBlend = (file.readUInt16() & 1) != 0
                
                regionMin = file.readVector3()
                regionMax = file.readVector3()
                
                _ = file.readUInt32()
            case "1":
                skeletonAnim = GFSkeletonAnim.init(withFile: file, frameCount: frameCount)
            case "3":
                materialAnim = GFMaterialAnim.init(withFile: file, frameCount: frameCount)
            case "6":
                visibilityAnim = GFVisibilityAnim.init(withFile: file, frameCount: frameCount)
            default: break
            }
        }
    }
}
