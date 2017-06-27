//
//  GFFragShaderContainter.swift
//  pm
//
//  Created by wanghuai on 2017/6/22.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFFragShaderContainer:GFContainer {
    var sections:[Section] = []
    var fragShaders:[GFFragShader] = []
    
    override init( withFile _file:FileHandle ) {
        super.init(withFile: _file)
        
        let sectionCount = file.readUInt32()
        file.skipPadding()
        sections = []
        for _ in 0 ..< sectionCount {
            var section = Section()
            section.magic = file.readString(len: 8)
            section.len = file.readUInt32()
            section.padding = file.readUInt32()
            section.addr = file.pos
            sections.append(section)
            file.seek(by: section.len)
        }
        
        fragShaders = []
        for section in sections {
            file.seek(to: section.addr)
            fragShaders.append(GFFragShader.init(withFile: file))
        }
    }
}
