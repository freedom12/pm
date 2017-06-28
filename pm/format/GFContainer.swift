//
//  GFContainer.swift
//  pm
//
//  Created by wanghuai on 2017/6/14.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFContainer {
    var file:FileHandle
    var magicNum:Int
    
    init( withFile _file:FileHandle ) {
        file = _file
        
        magicNum = file.readUInt32()
    }
}
