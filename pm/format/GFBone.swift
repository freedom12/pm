//
//  GFBone.swift
//  pm
//
//  Created by wanghuai on 2017/6/15.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFBone {
    var file:FileHandle
    var name = ""
    var parent = ""
    var flags = 0
    
    var scale = Vector3.init(0, 0, 0)
    var rotation = Vector3.init(0, 0, 0)
    var position = Vector3.init(0, 0, 0)
    
    init( withFile _file:FileHandle ) {
        file = _file
        
        name = file.readStringByte()
        parent = file.readStringByte()
        flags = file.readInt8()
        
        scale = file.readVector3()
        rotation = file.readVector3()
        position = file.readVector3()
    }
}
