//
//  GFFragShader.swift
//  pm
//
//  Created by wanghuai on 2017/6/22.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFFragShader {
    var file:FileHandle
    var name = ""
    var fileName = ""
    var texEnvStages:[TexEnvStage] = Array.init(repeating: TexEnvStage.init(), count: 6)
    var texEnvBufferColor = Color.init()
    
    init( withFile _file:FileHandle ) {
        file = _file
        
        name = file.readString(len: 0x40)
        
        _ = file.readUInt32()
        _ = file.readUInt32()
        
        file.skipPadding()
        
        let cmdLenght = file.readUInt32()
        _ = file.readUInt32()
        _ = file.readUInt32()
        _ = file.readUInt32()
        
        fileName = file.readString(len: 0x40)
        var datas:[Int] = []
        for _ in 0 ..< (cmdLenght >> 2) {
            datas.append(file.readUInt32())
        }
        
        let cmdReader = PICACommandReader.init(withDatas: datas)
        for cmd in cmdReader.cmds {
            let param = cmd.params[0]
            var stage = (cmd.register.rawValue >> 3) & 7
            if stage >= 6 {
                stage -= 2
            }
            
            switch cmd.register {
            case .GPUREG_TEXENV0_SOURCE: fallthrough
            case .GPUREG_TEXENV1_SOURCE: fallthrough
            case .GPUREG_TEXENV2_SOURCE: fallthrough
            case .GPUREG_TEXENV3_SOURCE: fallthrough
            case .GPUREG_TEXENV4_SOURCE: fallthrough
            case .GPUREG_TEXENV5_SOURCE: texEnvStages[stage].src = PICATexEnvSrc(withInt: param)
                
            case .GPUREG_TEXENV0_OPERAND: fallthrough
            case .GPUREG_TEXENV1_OPERAND: fallthrough
            case .GPUREG_TEXENV2_OPERAND: fallthrough
            case .GPUREG_TEXENV3_OPERAND: fallthrough
            case .GPUREG_TEXENV4_OPERAND: fallthrough
            case .GPUREG_TEXENV5_OPERAND: texEnvStages[stage].oprand = PICATexEnvOperand(withInt: param)
                
            case .GPUREG_TEXENV0_COMBINER: fallthrough
            case .GPUREG_TEXENV1_COMBINER: fallthrough
            case .GPUREG_TEXENV2_COMBINER: fallthrough
            case .GPUREG_TEXENV3_COMBINER: fallthrough
            case .GPUREG_TEXENV4_COMBINER: fallthrough
            case .GPUREG_TEXENV5_COMBINER: texEnvStages[stage].combinder = PICATexEnvMode(withInt: param)
                
            case .GPUREG_TEXENV0_COLOR: fallthrough
            case .GPUREG_TEXENV1_COLOR: fallthrough
            case .GPUREG_TEXENV2_COLOR: fallthrough
            case .GPUREG_TEXENV3_COLOR: fallthrough
            case .GPUREG_TEXENV4_COLOR: fallthrough
            case .GPUREG_TEXENV5_COLOR: texEnvStages[stage].color = Color.init(withInt: param)
                
            case .GPUREG_TEXENV0_SCALE: fallthrough
            case .GPUREG_TEXENV1_SCALE: fallthrough
            case .GPUREG_TEXENV2_SCALE: fallthrough
            case .GPUREG_TEXENV3_SCALE: fallthrough
            case .GPUREG_TEXENV4_SCALE: fallthrough
            case .GPUREG_TEXENV5_SCALE: texEnvStages[stage].scale = PICATexEnvScale.init(withInt: param)
                
            case .GPUREG_TEXENV_UPDATE_BUFFER:
                texEnvStages[1].updateColorBuffer = ((param & 0x100) != 0)
                texEnvStages[2].updateColorBuffer = ((param & 0x200) != 0)
                texEnvStages[3].updateColorBuffer = ((param & 0x400) != 0)
                texEnvStages[4].updateColorBuffer = ((param & 0x800) != 0)
                
                texEnvStages[1].updateAlphaBuffer = ((param & 0x1000) != 0)
                texEnvStages[2].updateAlphaBuffer = ((param & 0x2000) != 0)
                texEnvStages[3].updateAlphaBuffer = ((param & 0x4000) != 0)
                texEnvStages[4].updateAlphaBuffer = ((param & 0x8000) != 0)
            case .GPUREG_TEXENV_BUFFER_COLOR: texEnvBufferColor = Color.init(withInt: param)
                
            default: break
            }
        }
    }
}

struct TexEnvStage {
    var src = PICATexEnvSrc()
    var oprand = PICATexEnvOperand()
    var combinder = PICATexEnvMode()
    var color = Color.init()
    var scale = PICATexEnvScale()
    
    var updateColorBuffer = false
    var updateAlphaBuffer = false
}
