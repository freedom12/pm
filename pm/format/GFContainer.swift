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
    
    let GFModelConstant:Int = 0x15122117
    let GFTextureConstant:Int = 0x15041213
    let GFMotionConstant:Int = 0x00060000
    let BCHConstant:Int = 0x00484342
    
    init( withFile _file:FileHandle ) {
        file = _file
        
        magicNum = file.readUInt32()
    }
}
