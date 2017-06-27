//
//  PICAStruct.swift
//  pm
//
//  Created by wanghuai on 2017/6/22.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
import Metal

struct PICAAttr {
    var name:PICAAttrName = .position
    var formate:PICAAttrFormate = .byte
    var elements = 0
    var scale:Float = 0
}

struct PICAFixedAttr {
    var name:PICAAttrName = .position
    var value = Vector4.init(x: 0, y: 0, z: 0, w: 0)
}

struct PICAColorOpt {
    var fragMode:PICAFragMode = .defaut         //nouse
    var blendMode:PICABlendMode = .logical
    
    init() {
        fragMode = .defaut
        blendMode = .logical
    }
    init(withInt int:Int) {
        fragMode = PICAFragMode(rawValue: (int >> 0) & 3)!
        blendMode = PICABlendMode(rawValue: (int >> 8) & 1)!
    }
}

struct PICABlend {
    var colorOpt:PICABlenOpt = .funcAdd
    var alphaOPt:PICABlenOpt = .funcAdd
    var colorSrcFunc:PICABlendFunc = .zero
    var colorDstFunc:PICABlendFunc = .zero
    var alphaSrcFunc:PICABlendFunc = .zero
    var alphaDstFunc:PICABlendFunc = .zero
    
    init() {
        colorOpt = .funcAdd
        alphaOPt = .funcAdd
        colorSrcFunc = .zero
        colorDstFunc = .zero
        alphaSrcFunc = .zero
        alphaDstFunc = .zero
    }
    
    init( withInt int:Int) {
        colorOpt = PICABlenOpt(rawValue: (int >> 0) & 7)!
        alphaOPt = PICABlenOpt(rawValue: (int >> 8) & 7)!
        
        colorSrcFunc = PICABlendFunc(rawValue: (int >> 16) & 0xf)!
        colorDstFunc = PICABlendFunc(rawValue: (int >> 20) & 0xf)!
        
        alphaSrcFunc = PICABlendFunc(rawValue: (int >> 24) & 0xf)!
        alphaDstFunc = PICABlendFunc(rawValue: (int >> 28) & 0xf)!
    }
}

struct PICAAlphaTest {
    var enable = false
    var testFunc:PICATestFunc = .never
    var reference = 0
    
    init() {
        enable = false
        testFunc = .never
        reference = 0
    }
    
    init( withInt int:Int ) {
        enable = (int & 1) != 0
        testFunc = PICATestFunc(rawValue: (int >> 4) & 7)!
        reference = (int >> 8) & 0xff
    }
}

struct PICAStencilTest {
    var enable = false
    var testFunc:PICATestFunc = .never
    var reference = 0
    var bufferMask = 0
    var mask = 0
    
    
    init() {
        enable = false
        testFunc = .never
        reference = 0
        bufferMask = 0
        mask = 0
    }
    
    init( withInt int:Int ) {
        enable = (int & 1) != 0
        testFunc = PICATestFunc(rawValue: (int >> 4) & 7)!
        bufferMask = (int >> 8) & 0xff
        reference = (int >> 16) & 0xff
        mask = (int >> 24) & 0xff
    }
}

struct PICAStencilOpt {
    var failOpt:PICAStencilOp = .keep
    var zFailOpt:PICAStencilOp = .keep
    var zPassOpt:PICAStencilOp = .keep
    
    init() {}
    init( withInt int:Int) {
        failOpt = PICAStencilOp(rawValue: (int >> 0) & 7)!
        zFailOpt = PICAStencilOp(rawValue: (int >> 4) & 7)!
        zPassOpt = PICAStencilOp(rawValue: (int >> 8) & 7)!
    }
}

struct PICADepthColorMask {
    var enable = false
    var depthFunc:PICATestFunc = .never
    var rWrite = false
    var gWrite = false
    var bWrite = false
    var aWrite = false
    var depthWrite = false
    
    init() {}
    init( withInt int:Int ) {
        enable = (int & 0x0001) != 0
        depthFunc = PICATestFunc.init(rawValue: (int >> 4) & 7)!
        rWrite = (int & 0x0100) != 0
        gWrite = (int & 0x0200) != 0
        bWrite = (int & 0x0400) != 0
        aWrite = (int & 0x0800) != 0
        depthWrite = (int & 0x1000) != 0
    }
    
    func getWriteMask() -> MTLColorWriteMask {
        var mask:UInt = 0
        if self.rWrite {
            mask |= MTLColorWriteMask.red.rawValue
        }
        if self.gWrite {
            mask |= MTLColorWriteMask.green.rawValue
        }
        if self.bWrite {
            mask |= MTLColorWriteMask.blue.rawValue
        }
        if self.aWrite {
            mask |= MTLColorWriteMask.alpha.rawValue
        }
        
        return MTLColorWriteMask.init(rawValue: mask)
    }
}

struct PICALutInAbs {
    var dist0 = false
    var dist1 = false
    var specular = false
    var fresnel = false
    var reflecR = false
    var reflecG = false
    var reflecB = false
    init() {}
    init( withInt int:Int) {
        dist0 = (int & 0x00000002) == 0
        dist1 = (int & 0x00000002) == 0
        specular = (int & 0x00000200) == 0
        fresnel = (int & 0x00002000) == 0
        reflecR = (int & 0x00020000) == 0
        reflecG = (int & 0x00200000) == 0
        reflecB = (int & 0x02000000) == 0
    }
}

struct PICALutInSel {
    var dist0:PICALutSel = .cosNormalHalf
    var dist1:PICALutSel = .cosNormalHalf
    var specular:PICALutSel = .cosNormalHalf
    var fresnel:PICALutSel = .cosNormalHalf
    var reflecR:PICALutSel = .cosNormalHalf
    var reflecG:PICALutSel = .cosNormalHalf
    var reflecB:PICALutSel = .cosNormalHalf
    init() {}
    init( withInt int:Int) {
        dist0 = PICALutSel(rawValue: (int >> 0) & 7)!
        dist1 = PICALutSel(rawValue: (int >> 4) & 7)!
        specular = PICALutSel(rawValue: (int >> 8) & 7)!
        fresnel = PICALutSel(rawValue: (int >> 12) & 7)!
        reflecR = PICALutSel(rawValue: (int >> 16) & 7)!
        reflecG = PICALutSel(rawValue: (int >> 20) & 7)!
        reflecB = PICALutSel(rawValue: (int >> 24) & 7)!
    }
}

struct PICALutInScale {
    var dist0:PICALutScale = .one
    var dist1:PICALutScale = .one
    var specular:PICALutScale = .one
    var fresnel:PICALutScale = .one
    var reflecR:PICALutScale = .one
    var reflecG:PICALutScale = .one
    var reflecB:PICALutScale = .one
    init() {}
    init( withInt int:Int) {
        dist0 = PICALutScale(rawValue: (int >> 0) & 7)!
        dist1 = PICALutScale(rawValue: (int >> 4) & 7)!
        specular = PICALutScale(rawValue: (int >> 8) & 7)!
        fresnel = PICALutScale(rawValue: (int >> 12) & 7)!
        reflecR = PICALutScale(rawValue: (int >> 16) & 7)!
        reflecG = PICALutScale(rawValue: (int >> 20) & 7)!
        reflecB = PICALutScale(rawValue: (int >> 24) & 7)!
    }
}

struct PICATexEnvSrc {
    var color:[PICATextureCombinerSrc] = Array.init(repeating: PICATextureCombinerSrc.primaryColor, count: 3)
    var alpha:[PICATextureCombinerSrc] = Array.init(repeating: PICATextureCombinerSrc.primaryColor, count: 3)
    init() {}
    init( withInt int:Int) {
        color[0] = PICATextureCombinerSrc(rawValue: (int >> 0) & 0xf)!
        color[1] = PICATextureCombinerSrc(rawValue: (int >> 4) & 0xf)!
        color[2] = PICATextureCombinerSrc(rawValue: (int >> 8) & 0xf)!
        
        alpha[0] = PICATextureCombinerSrc(rawValue: (int >> 16) & 0xf)!
        alpha[1] = PICATextureCombinerSrc(rawValue: (int >> 20) & 0xf)!
        alpha[2] = PICATextureCombinerSrc(rawValue: (int >> 24) & 0xf)!
    }
}

struct PICATexEnvOperand {
    var color:[PICATextureCombinerColorOp] = Array.init(repeating: PICATextureCombinerColorOp.color, count: 3)
    var alpha:[PICATextureCombinerAlphaOp] = Array.init(repeating: PICATextureCombinerAlphaOp.alpha, count: 3)
    init() {}
    init( withInt int:Int) {
        color[0] = PICATextureCombinerColorOp(rawValue: (int >> 0) & 0xf)!
        color[1] = PICATextureCombinerColorOp(rawValue: (int >> 4) & 0xf)!
        color[2] = PICATextureCombinerColorOp(rawValue: (int >> 8) & 0xf)!
        
        alpha[0] = PICATextureCombinerAlphaOp(rawValue: (int >> 16) & 0xf)!
        alpha[1] = PICATextureCombinerAlphaOp(rawValue: (int >> 20) & 0xf)!
        alpha[2] = PICATextureCombinerAlphaOp(rawValue: (int >> 24) & 0xf)!
    }
}

struct PICATexEnvMode {
    var color = PICATextureCombinerMode.replace
    var alpha = PICATextureCombinerMode.replace
    init() {}
    init(withInt int:Int) {
        color = PICATextureCombinerMode(rawValue: (int >> 0) & 0xf)!
        alpha = PICATextureCombinerMode(rawValue: (int >> 16) & 0xf)!
    }
}

struct PICATexEnvScale {
    var color = PICATextureCombinerScale.one
    var alpha = PICATextureCombinerScale.one
    init() {}
    init(withInt int:Int) {
        color = PICATextureCombinerScale(rawValue: (int >> 0) & 3)!
        alpha = PICATextureCombinerScale(rawValue: (int >> 16) & 3)!
    }
}
