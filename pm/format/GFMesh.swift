//
//  GFMesh.swift
//  pm
//
//  Created by wanghuai on 2017/6/16.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFMesh {
    var file:FileHandle
    
    init( withFile _file:FileHandle ) {
        file = _file
    }
    
    var _name:String = ""
    var name:String {
        get {
            return _name
        }
        set {
            _name = newValue
        }
    }
}
