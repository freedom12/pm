//
//  GFLut.swift
//  pm
//
//  Created by wanghuai on 2017/6/15.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFLut {
    var file:FileHandle
    var hash = 0
    var table:[Float] = []
    init( withFile _file:FileHandle, andLen _len:Int ) {
        file = _file
        hash = file.readUInt32()
        
        file.seek(by: 0xc)
        
        let count = _len >> 2
        
        var datas:[Int] = []
        for _ in 0...(count-1) {
            datas.append(file.readUInt32())
        }
        
        let cmdReader = PICACommandReader.init(withDatas: datas)
        table = Array.init(repeating: 0, count: 256)
        var index = 0
        for cmd in cmdReader.cmds {
            switch cmd.register {
            case .GPUREG_LIGHTING_LUT_INDEX:
                index = cmd.params[0] & 0xff
            case .GPUREG_LIGHTING_LUT_DATA0,
                 .GPUREG_LIGHTING_LUT_DATA1,
                 .GPUREG_LIGHTING_LUT_DATA2,
                 .GPUREG_LIGHTING_LUT_DATA3,
                 .GPUREG_LIGHTING_LUT_DATA4,
                 .GPUREG_LIGHTING_LUT_DATA5,
                 .GPUREG_LIGHTING_LUT_DATA6,
                 .GPUREG_LIGHTING_LUT_DATA7:
                for param in cmd.params {
                    table[index] = Float(param & 0xfff) / 0xfff
                    index = index + 1
                }
             default: break
            }
        }
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
