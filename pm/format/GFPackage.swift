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
    var file:FileHandle
    var magic:String = ""
    var entries:[Entry] = []
    var containters:[GFContainer] = []
    
    init( withFile _file:FileHandle ) {
        file = _file
        file.seek(toFileOffset: 0)
        
        magic = file.readString(len: 2)
        let entryCount = file.readUInt16()
        entries = []
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
        
        containters = []
        for i in 0 ..< 1 {
            file.seek(to: entries[i].addr)
            containters.append(GFModelContainter.init(withFile: file))
        }
    }
}
