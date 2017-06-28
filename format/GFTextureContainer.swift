//
//  GFTextureContainer.swift
//  pm
//
//  Created by wanghuai on 2017/6/21.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFTextureContainer:GFContainer {
    var sections:[Section] = []
    var textures:[GFTexture] = []
    override init( withFile _file:FileHandle ) {
        super.init(withFile: _file)
        
        let sectionCount = file.readUInt32()
        
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
        
        for section in sections {
            file.seek(to: section.addr)
            textures.append(GFTexture.init(withFile: file))
        }
    }
}
