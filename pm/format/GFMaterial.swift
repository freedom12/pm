//
//  GFMaterial.swift
//  pm
//
//  Created by wanghuai on 2017/6/16.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
//import UIKit

class GFMaterial {
    var file:FileHandle
    var materialName = HashName.init()
    var geoShaderName = HashName.init()
    var vertShaderName = HashName.init()
    var fragShaderName = HashName.init()
    
    var lut0Hash = 0
    var lut1Hash = 0
    var lut2Hash = 0
    
    var bumpTexture = Data.init()
    
    var constant0Assignment = Data.init()
    var constant1Assignment = Data.init()
    var constant2Assignment = Data.init()
    var constant3Assignment = Data.init()
    var constant4Assignment = Data.init()
    var constant5Assignment = Data.init()
    
    var constant0Color = Color.init()
    var constant1Color = Color.init()
    var constant2Color = Color.init()
    var constant3Color = Color.init()
    var constant4Color = Color.init()
    var constant5Color = Color.init()
    var specular0Color = Color.init()
    var specular1Color = Color.init()
    var blendColor = Color.init()
    var EmissionColor = Color.init()
    var AmbientColor = Color.init()
    var DiffuseColor = Color.init()
    
    var edgeType = 0
    var edgeIdEnable = 0
    var edgeId = 0
    var projectionType = 0
    var rimPower:Float = 0.0
    var rimScale:Float = 0.0
    var phongPower:Float = 0.0
    var phongScale:Float = 0.0
    var edgeIdOffsetEnable = 0
    var edgeMapAlphaMask = 0
    var bakeTexture0 = 0
    var bakeTexture1 = 0
    var bakeTexture2 = 0
    var bakeConstant0 = 0
    var bakeConstant1 = 0
    var bakeConstant2 = 0
    var bakeConstant3 = 0
    var bakeConstant4 = 0
    var bakeConstant5 = 0
    var vertShaderType = 0
    var shaderParam0:Float = 0.0
    var shaderParam1:Float = 0.0
    var shaderParam2:Float = 0.0
    var shaderParam3:Float = 0.0
    
    var samplers:[GFSampler] = []
    
    var renderPriority = 0
    var renderLayer = 0
    
    var borderColor:[Color] = Array.init(repeating: Color.init(), count: 3)
    var colorOpt = PICAColorOpt.init()
    var blend = PICABlend.init()
    var logicalOpt:PICALogicalOpt = .clear
    var alphaTest = PICAAlphaTest.init()
    var stencilTest = PICAStencilTest.init()
    var stencilOpt = PICAStencilOpt.init()
    var depthColorMask = PICADepthColorMask.init()
    var faceCulling:PICAFaceCulling = .never
    var colorBufferRead = false
    var colorBufferWrite = false
    var depthBufferRead = false
    var depthBufferWrite = false
    var stencilBufferRead = false
    var stencilBufferWrite = false
    var lutInAbs = PICALutInAbs.init()
    var lutInSel = PICALutInSel.init()
    var lutInScale = PICALutInScale.init()
    
    var textureSrcs:[Float] = []
    
    init( withFile _file:FileHandle ) {
        file = _file
        
        materialName = HashName.init(withFile: file)
        geoShaderName = HashName.init(withFile: file)
        vertShaderName = HashName.init(withFile: file)
        fragShaderName = HashName.init(withFile: file)
        
        lut0Hash = file.readUInt32()
        lut1Hash = file.readUInt32()
        lut2Hash = file.readUInt32()
        
        _ = file.readUInt32()   //this seam to be always 0
        
        bumpTexture = file.readSByte()
        
        constant0Assignment = file.readByte()
        constant1Assignment = file.readByte()
        constant2Assignment = file.readByte()
        constant3Assignment = file.readByte()
        constant4Assignment = file.readByte()
        constant5Assignment = file.readByte()
        
        _ = file.readByte()     //0x0
        
        constant0Color = Color.init(withFile: file)
        constant1Color = Color.init(withFile: file)
        constant2Color = Color.init(withFile: file)
        constant3Color = Color.init(withFile: file)
        constant4Color = Color.init(withFile: file)
        constant5Color = Color.init(withFile: file)
        specular0Color = Color.init(withFile: file)
        specular1Color = Color.init(withFile: file)
        blendColor = Color.init(withFile: file)
        EmissionColor = Color.init(withFile: file)
        AmbientColor = Color.init(withFile: file)
        DiffuseColor = Color.init(withFile: file)
        
        edgeType = file.readInt32()
        edgeIdEnable = file.readInt32()
        edgeId = file.readInt32()
        projectionType = file.readInt32()
        rimPower = file.readSingle()
        rimScale = file.readSingle()
        phongPower = file.readSingle()
        phongScale = file.readSingle()
        edgeIdOffsetEnable = file.readInt32()
        edgeMapAlphaMask = file.readInt32()
        bakeTexture0 = file.readInt32()
        bakeTexture1 = file.readInt32()
        bakeTexture2 = file.readInt32()
        bakeConstant0 = file.readInt32()
        bakeConstant1 = file.readInt32()
        bakeConstant2 = file.readInt32()
        bakeConstant3 = file.readInt32()
        bakeConstant4 = file.readInt32()
        bakeConstant5 = file.readInt32()
        vertShaderType = file.readInt32()
        shaderParam0 = file.readSingle()
        shaderParam1 = file.readSingle()
        shaderParam2 = file.readSingle()
        shaderParam3 = file.readSingle()
        
        let unitCount = file.readUInt32()
        samplers = []
        for _ in 0 ..< unitCount {
            let sampler = GFSampler.init(withFile: file)
            samplers.append(sampler)
        }
        
        file.skipPadding()
        
        let cmdLenght = file.readUInt32()
        
        renderPriority = file.readInt32()
        _ = file.readUInt32()
        renderLayer = file.readInt32()
        _ = file.readUInt32()
        _ = file.readUInt32()
        _ = file.readUInt32()
        _ = file.readUInt32()
        
        var datas:[Int] = []
        for _ in 0 ..< (cmdLenght >> 2) {
            datas.append(file.readUInt32())
        }
        
        let cmdReader = PICACommandReader.init(withDatas: datas)
        for cmd in cmdReader.cmds {
            let param = cmd.params[0]
            switch cmd.register {
            case .GPUREG_TEXUNIT0_BORDER_COLOR: borderColor[0] = Color.init(withInt: param)
            case .GPUREG_TEXUNIT1_BORDER_COLOR: borderColor[1] = Color.init(withInt: param)
            case .GPUREG_TEXUNIT2_BORDER_COLOR: borderColor[2] = Color.init(withInt: param)
            case .GPUREG_COLOR_OPERATION: colorOpt = PICAColorOpt.init(withInt: param)
            case .GPUREG_BLEND_FUNC: blend = PICABlend.init(withInt: param)
            case .GPUREG_LOGIC_OP: logicalOpt = PICALogicalOpt(rawValue: (param & 0xf))!
            case .GPUREG_FRAGOP_ALPHA_TEST: alphaTest = PICAAlphaTest.init(withInt: param)
            case .GPUREG_STENCIL_TEST: stencilTest = PICAStencilTest.init(withInt: param)
            case .GPUREG_STENCIL_OP: stencilOpt = PICAStencilOpt.init(withInt: param)
            case .GPUREG_DEPTH_COLOR_MASK: depthColorMask = PICADepthColorMask.init(withInt: param)
            case .GPUREG_FACECULLING_CONFIG: faceCulling = PICAFaceCulling(rawValue: (param & 3))!
            case .GPUREG_COLORBUFFER_READ: colorBufferRead = (param & 0xf) == 0xf
            case .GPUREG_COLORBUFFER_WRITE: colorBufferWrite = (param & 0xf) == 0xf
            case .GPUREG_DEPTHBUFFER_READ:
                stencilBufferRead = (param & 1) != 0
                depthBufferRead = (param & 2) != 0
            case .GPUREG_DEPTHBUFFER_WRITE:
                stencilBufferWrite = (param & 1) != 0
                depthBufferWrite = (param & 2) != 0
            case .GPUREG_LIGHTING_LUTINPUT_ABS: lutInAbs = PICALutInAbs.init(withInt: param)
            case .GPUREG_LIGHTING_LUTINPUT_SELECT: lutInSel = PICALutInSel.init(withInt: param)
            case .GPUREG_LIGHTING_LUTINPUT_SCALE: lutInScale = PICALutInScale.init(withInt: param)
            default: break
            }
        }

        textureSrcs = []
        textureSrcs.append(cmdReader.uniforms[0].x)
        textureSrcs.append(cmdReader.uniforms[0].y)
        textureSrcs.append(cmdReader.uniforms[0].z)
        textureSrcs.append(cmdReader.uniforms[0].w)
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

