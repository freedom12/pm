//
//  PICACommandReader.swift
//  pm
//
//  Created by wanghuai on 2017/6/16.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

struct PICACommand {
    var register:PICARegister = .GPUREG_DUMMY
    var params:[Int] = []
    var mask = 0
}

class PICACommandReader {
    var cmds:[PICACommand] = []
    var uniforms:[Vector4] = []
    
    init( withDatas datas:[Int] ) {
        cmds = []
        uniforms = Array.init(repeating: Vector4.init(0, 0, 0, 0), count: 96)
        
        var index = 0
        while (index < datas.count) {
            var param = datas[index]
            index = index + 1
            let cmd = datas[index]
            index = index + 1
            
            var id = (cmd >> 0) & 0xffff
            let mask = (cmd >> 16) & 0xf
            let extParam = (cmd >> 20) & 0x7ff
            let isConsecutive = (cmd >> 31) != 0
            
            if (isConsecutive) {
                for i in 0 ... extParam {
                    var cmd = PICACommand()
                    cmd.register = PICARegister.init(rawValue: id)!
                    cmd.params = [param]
                    cmd.mask = mask
                    id = id + 1
                    checkUniforms(withCmd: cmd)
                    cmds.append(cmd)
                    if (i < extParam) {
                        param = datas[index]
                        index = index + 1
                    }
                }
            } else {
                var cmd = PICACommand()
                cmd.register = PICARegister.init(rawValue: id)!
                cmd.params = [param]
                cmd.mask = mask
                
                for _ in 0 ..< extParam {
                    cmd.params.append(datas[index])
                    index = index + 1
                }
                checkUniforms(withCmd: cmd)
                cmds.append(cmd)
            }
            
            if ((index & 1) != 0) {
                index = index + 1
            }
        }
    }
    
    private var uniformIndex = 0
    private var isUniform32Bits = false
    private var words:[Int] = Array.init(repeating: 0, count: 3)
    private func checkUniforms( withCmd cmd:PICACommand ) {
        switch cmd.register {
        case .GPUREG_VSH_FLOATUNIFORM_INDEX:
            uniformIndex = (cmd.params[0] & 0xff) << 2
            isUniform32Bits = (cmd.params[0] >> 31) != 0
        case .GPUREG_VSH_FLOATUNIFORM_DATA0,
             .GPUREG_VSH_FLOATUNIFORM_DATA1,
             .GPUREG_VSH_FLOATUNIFORM_DATA2,
             .GPUREG_VSH_FLOATUNIFORM_DATA3,
             .GPUREG_VSH_FLOATUNIFORM_DATA4,
             .GPUREG_VSH_FLOATUNIFORM_DATA5,
             .GPUREG_VSH_FLOATUNIFORM_DATA6,
             .GPUREG_VSH_FLOATUNIFORM_DATA7:
            for param in cmd.params {
                let index = uniformIndex >> 2
                if (isUniform32Bits) {
                    var tmp = UInt32(param)
                    let data = NSData.init(bytes: &tmp, length: 4)
                    var value:Float = 0
                    data.getBytes(&value, length: 4)
                    
                    switch (uniformIndex & 3) {
                    case 0: uniforms[index].x = value
                    case 1: uniforms[index].y = value
                    case 2: uniforms[index].z = value
                    case 3: uniforms[index].w = value
                    default: break
                    }
                } else {
                    words[uniformIndex & 3] = param
                    if ((uniformIndex & 3) == 2) {
                        uniformIndex = uniformIndex + 1
                        
                        let x = getFloat24(value: words[2] & 0xffffff)
                        let y = getFloat24(value: (words[2] >> 24) | ((words[1] & 0xffffff) << 8))
                        let z = getFloat24(value: (words[1] >> 16) | ((words[0] & 0xff) << 16))
                        let w = getFloat24(value: words[0] >> 8)
                        
                        uniforms[index] = Vector4.init(x, y, z, w)
                    }
                }
                
                uniformIndex = uniformIndex + 1
            }
        default: break
        }
    }
    
    private func getFloat24( value:Int ) -> Float {
        var tmpValue = 0
        if ((value & 0x7fffff) != 0) {
            let mantissa = value & 0xffff
            let exponent = ((value >> 16) & 0x7f) + 64
            let signBit = (value >> 23) & 1
            
            tmpValue = mantissa << 7
            tmpValue = tmpValue | (exponent << 23)
            tmpValue = tmpValue | (signBit << 31)
        } else {
            tmpValue = (value & 0x800000) << 8
        }
        
        var tmp = UInt32(tmpValue)
        let data = NSData.init(bytes: &tmp, length: 4)
        var ret:Float = 0
        data.getBytes(&ret, length: 4)
        
        return ret
    }
}

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

enum PICAFragMode:Int {
    case defaut = 0
    case gas
    case shadow
}

enum PICABlendMode:Int {
    case logical = 0
    case blend
}

struct PICAColorOpt {
    var fragMode:PICAFragMode = .defaut
    var blendMode:PICABlendMode = .logical
    
    init() {
        fragMode = .defaut
        blendMode = .logical
    }
    init(withInt int:Int) {
        fragMode = PICAFragMode.init(rawValue: (int >> 0) & 3)!
        blendMode = PICABlendMode.init(rawValue: (int >> 8) & 1)!
    }
}

enum PICABlenOpt:Int {
    case funcAdd = 0
    case funcSub
    case funcReverseSub
    case min
    case max
}

enum PICABlendFunc:Int {
    case zero = 0
    case one
    case srcColor
    case oneMinusSrcColor
    case dstColor
    case oneMinusDesColor
    case srcAlpha
    case oneMinusSrcAlpha
    case dstAlpha
    case oneMinusDstAlpha
    case constColor
    case oneMinusConstColor
    case constAlpha
    case oneMinusConstAlpha
    case srcAlphaSaturate
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
        colorOpt = PICABlenOpt.init(rawValue: (int >> 0) & 7)!
        alphaOPt = PICABlenOpt.init(rawValue: (int >> 8) & 7)!
        
        colorSrcFunc = PICABlendFunc.init(rawValue: (int >> 16) & 0xf)!
        colorDstFunc = PICABlendFunc.init(rawValue: (int >> 20) & 0xf)!
        
        alphaSrcFunc = PICABlendFunc.init(rawValue: (int >> 24) & 0xf)!
        alphaDstFunc = PICABlendFunc.init(rawValue: (int >> 28) & 0xf)!
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
        testFunc = PICATestFunc.init(rawValue: (int >> 4) & 7)!
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
        testFunc = PICATestFunc.init(rawValue: (int >> 4) & 7)!
        bufferMask = (int >> 8) & 0xff
        reference = (int >> 16) & 0xff
        mask = (int >> 24) & 0xff
    }
}


enum PICATestFunc:Int {
    case never = 0
    case always
    case equal
    case notEqual
    case less
    case lessEqual
    case greater
    case greaterEqual
}

struct PICAStencilOpt {
    var failOpt:PICAStencilOp = .keep
    var zFailOpt:PICAStencilOp = .keep
    var zPassOpt:PICAStencilOp = .keep
    
    init() {}
    init( withInt int:Int) {
        failOpt = PICAStencilOp.init(rawValue: (int >> 0) & 7)!
        zFailOpt = PICAStencilOp.init(rawValue: (int >> 4) & 7)!
        zPassOpt = PICAStencilOp.init(rawValue: (int >> 8) & 7)!
    }
}

enum PICAStencilOp:Int {
    case keep = 0
    case zero
    case replace
    case inc
    case dec
    case invert
    case incWrap
    case decWrap
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
        dist0 = PICALutSel.init(rawValue: (int >> 0) & 7)!
        dist1 = PICALutSel.init(rawValue: (int >> 4) & 7)!
        specular = PICALutSel.init(rawValue: (int >> 8) & 7)!
        fresnel = PICALutSel.init(rawValue: (int >> 12) & 7)!
        reflecR = PICALutSel.init(rawValue: (int >> 16) & 7)!
        reflecG = PICALutSel.init(rawValue: (int >> 20) & 7)!
        reflecB = PICALutSel.init(rawValue: (int >> 24) & 7)!
    }
}

enum PICALutSel:Int {
    case cosNormalHalf = 0
    case cosViewHalf
    case cosNormalView
    case cosLightNormal
    case cosLightSpot
    case cosPhi
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
        dist0 = PICALutScale.init(rawValue: (int >> 0) & 7)!
        dist1 = PICALutScale.init(rawValue: (int >> 4) & 7)!
        specular = PICALutScale.init(rawValue: (int >> 8) & 7)!
        fresnel = PICALutScale.init(rawValue: (int >> 12) & 7)!
        reflecR = PICALutScale.init(rawValue: (int >> 16) & 7)!
        reflecG = PICALutScale.init(rawValue: (int >> 20) & 7)!
        reflecB = PICALutScale.init(rawValue: (int >> 24) & 7)!
    }
}

enum PICALutScale:Int {
    case one = 0
    case two = 1
    case four = 2
    case eight = 3
    case quarter = 6
    case half = 7
}

enum PICARegister:Int {
    case GPUREG_DUMMY = 0x0000
    case GPUREG_FINALIZE = 0x0010
    case GPUREG_FACECULLING_CONFIG = 0x0040
    case GPUREG_VIEWPORT_WIDTH = 0x0041
    case GPUREG_VIEWPORT_INVW = 0x0042
    case GPUREG_VIEWPORT_HEIGHT = 0x0043
    case GPUREG_VIEWPORT_INVH = 0x0044
    case GPUREG_FRAGOP_CLIP = 0x0047
    case GPUREG_FRAGOP_CLIP_DATA0 = 0x0048
    case GPUREG_FRAGOP_CLIP_DATA1 = 0x0049
    case GPUREG_FRAGOP_CLIP_DATA2 = 0x004A
    case GPUREG_FRAGOP_CLIP_DATA3 = 0x004B
    case GPUREG_DEPTHMAP_SCALE = 0x004D
    case GPUREG_DEPTHMAP_OFFSET = 0x004E
    case GPUREG_SH_OUTMAP_TOTAL = 0x004F
    case GPUREG_SH_OUTMAP_O0 = 0x0050
    case GPUREG_SH_OUTMAP_O1 = 0x0051
    case GPUREG_SH_OUTMAP_O2 = 0x0052
    case GPUREG_SH_OUTMAP_O3 = 0x0053
    case GPUREG_SH_OUTMAP_O4 = 0x0054
    case GPUREG_SH_OUTMAP_O5 = 0x0055
    case GPUREG_SH_OUTMAP_O6 = 0x0056
    case GPUREG_EARLYDEPTH_FUNC = 0x0061
    case GPUREG_EARLYDEPTH_TEST1 = 0x0062
    case GPUREG_EARLYDEPTH_CLEAR = 0x0063
    case GPUREG_SH_OUTATTR_MODE = 0x0064
    case GPUREG_SCISSORTEST_MODE = 0x0065
    case GPUREG_SCISSORTEST_POS = 0x0066
    case GPUREG_SCISSORTEST_DIM = 0x0067
    case GPUREG_VIEWPORT_XY = 0x0068
    case GPUREG_EARLYDEPTH_DATA = 0x006A
    case GPUREG_DEPTHMAP_ENABLE = 0x006D
    case GPUREG_RENDERBUF_DIM = 0x006E
    case GPUREG_SH_OUTATTR_CLOCK = 0x006F
    case GPUREG_TEXUNIT_CONFIG = 0x0080
    case GPUREG_TEXUNIT0_BORDER_COLOR = 0x0081
    case GPUREG_TEXUNIT0_DIM = 0x0082
    case GPUREG_TEXUNIT0_PARAM = 0x0083
    case GPUREG_TEXUNIT0_LOD = 0x0084
    case GPUREG_TEXUNIT0_ADDR1 = 0x0085
    case GPUREG_TEXUNIT0_ADDR2 = 0x0086
    case GPUREG_TEXUNIT0_ADDR3 = 0x0087
    case GPUREG_TEXUNIT0_ADDR4 = 0x0088
    case GPUREG_TEXUNIT0_ADDR5 = 0x0089
    case GPUREG_TEXUNIT0_ADDR6 = 0x008A
    case GPUREG_TEXUNIT0_SHADOW = 0x008B
    case GPUREG_TEXUNIT0_TYPE = 0x008E
    case GPUREG_LIGHTING_ENABLE0 = 0x008F
    case GPUREG_TEXUNIT1_BORDER_COLOR = 0x0091
    case GPUREG_TEXUNIT1_DIM = 0x0092
    case GPUREG_TEXUNIT1_PARAM = 0x0093
    case GPUREG_TEXUNIT1_LOD = 0x0094
    case GPUREG_TEXUNIT1_ADDR = 0x0095
    case GPUREG_TEXUNIT1_TYPE = 0x0096
    case GPUREG_TEXUNIT2_BORDER_COLOR = 0x0099
    case GPUREG_TEXUNIT2_DIM = 0x009A
    case GPUREG_TEXUNIT2_PARAM = 0x009B
    case GPUREG_TEXUNIT2_LOD = 0x009C
    case GPUREG_TEXUNIT2_ADDR = 0x009D
    case GPUREG_TEXUNIT2_TYPE = 0x009E
    case GPUREG_TEXUNIT3_PROCTEX0 = 0x00A8
    case GPUREG_TEXUNIT3_PROCTEX1 = 0x00A9
    case GPUREG_TEXUNIT3_PROCTEX2 = 0x00AA
    case GPUREG_TEXUNIT3_PROCTEX3 = 0x00AB
    case GPUREG_TEXUNIT3_PROCTEX4 = 0x00AC
    case GPUREG_TEXUNIT3_PROCTEX5 = 0x00AD
    case GPUREG_PROCTEX_LUT = 0x00AF
    case GPUREG_PROCTEX_LUT_DATA0 = 0x00B0
    case GPUREG_PROCTEX_LUT_DATA1 = 0x00B1
    case GPUREG_PROCTEX_LUT_DATA2 = 0x00B2
    case GPUREG_PROCTEX_LUT_DATA3 = 0x00B3
    case GPUREG_PROCTEX_LUT_DATA4 = 0x00B4
    case GPUREG_PROCTEX_LUT_DATA5 = 0x00B5
    case GPUREG_PROCTEX_LUT_DATA6 = 0x00B6
    case GPUREG_PROCTEX_LUT_DATA7 = 0x00B7
    case GPUREG_TEXENV0_SOURCE = 0x00C0
    case GPUREG_TEXENV0_OPERAND = 0x00C1
    case GPUREG_TEXENV0_COMBINER = 0x00C2
    case GPUREG_TEXENV0_COLOR = 0x00C3
    case GPUREG_TEXENV0_SCALE = 0x00C4
    case GPUREG_TEXENV1_SOURCE = 0x00C8
    case GPUREG_TEXENV1_OPERAND = 0x00C9
    case GPUREG_TEXENV1_COMBINER = 0x00CA
    case GPUREG_TEXENV1_COLOR = 0x00CB
    case GPUREG_TEXENV1_SCALE = 0x00CC
    case GPUREG_TEXENV2_SOURCE = 0x00D0
    case GPUREG_TEXENV2_OPERAND = 0x00D1
    case GPUREG_TEXENV2_COMBINER = 0x00D2
    case GPUREG_TEXENV2_COLOR = 0x00D3
    case GPUREG_TEXENV2_SCALE = 0x00D4
    case GPUREG_TEXENV3_SOURCE = 0x00D8
    case GPUREG_TEXENV3_OPERAND = 0x00D9
    case GPUREG_TEXENV3_COMBINER = 0x00DA
    case GPUREG_TEXENV3_COLOR = 0x00DB
    case GPUREG_TEXENV3_SCALE = 0x00DC
    case GPUREG_TEXENV_UPDATE_BUFFER = 0x00E0
    case GPUREG_FOG_COLOR = 0x00E1
    case GPUREG_GAS_ATTENUATION = 0x00E4
    case GPUREG_GAS_ACCMAX = 0x00E5
    case GPUREG_FOG_LUT_INDEX = 0x00E6
    case GPUREG_FOG_LUT_DATA0 = 0x00E8
    case GPUREG_FOG_LUT_DATA1 = 0x00E9
    case GPUREG_FOG_LUT_DATA2 = 0x00EA
    case GPUREG_FOG_LUT_DATA3 = 0x00EB
    case GPUREG_FOG_LUT_DATA4 = 0x00EC
    case GPUREG_FOG_LUT_DATA5 = 0x00ED
    case GPUREG_FOG_LUT_DATA6 = 0x00EE
    case GPUREG_FOG_LUT_DATA7 = 0x00EF
    case GPUREG_TEXENV4_SOURCE = 0x00F0
    case GPUREG_TEXENV4_OPERAND = 0x00F1
    case GPUREG_TEXENV4_COMBINER = 0x00F2
    case GPUREG_TEXENV4_COLOR = 0x00F3
    case GPUREG_TEXENV4_SCALE = 0x00F4
    case GPUREG_TEXENV5_SOURCE = 0x00F8
    case GPUREG_TEXENV5_OPERAND = 0x00F9
    case GPUREG_TEXENV5_COMBINER = 0x00FA
    case GPUREG_TEXENV5_COLOR = 0x00FB
    case GPUREG_TEXENV5_SCALE = 0x00FC
    case GPUREG_TEXENV_BUFFER_COLOR = 0x00FD
    case GPUREG_COLOR_OPERATION = 0x0100
    case GPUREG_BLEND_FUNC = 0x0101
    case GPUREG_LOGIC_OP = 0x0102
    case GPUREG_BLEND_COLOR = 0x0103
    case GPUREG_FRAGOP_ALPHA_TEST = 0x0104
    case GPUREG_STENCIL_TEST = 0x0105
    case GPUREG_STENCIL_OP = 0x0106
    case GPUREG_DEPTH_COLOR_MASK = 0x0107
    case GPUREG_FRAMEBUFFER_INVALIDATE = 0x0110
    case GPUREG_FRAMEBUFFER_FLUSH = 0x0111
    case GPUREG_COLORBUFFER_READ = 0x0112
    case GPUREG_COLORBUFFER_WRITE = 0x0113
    case GPUREG_DEPTHBUFFER_READ = 0x0114
    case GPUREG_DEPTHBUFFER_WRITE = 0x0115
    case GPUREG_DEPTHBUFFER_FORMAT = 0x0116
    case GPUREG_COLORBUFFER_FORMAT = 0x0117
    case GPUREG_EARLYDEPTH_TEST2 = 0x0118
    case GPUREG_FRAMEBUFFER_BLOCK32 = 0x011B
    case GPUREG_DEPTHBUFFER_LOC = 0x011C
    case GPUREG_COLORBUFFER_LOC = 0x011D
    case GPUREG_FRAMEBUFFER_DIM = 0x011E
    case GPUREG_GAS_LIGHT_XY = 0x0120
    case GPUREG_GAS_LIGHT_Z = 0x0121
    case GPUREG_GAS_LIGHT_Z_COLOR = 0x0122
    case GPUREG_GAS_LUT_INDEX = 0x0123
    case GPUREG_GAS_LUT_DATA = 0x0124
    case GPUREG_GAS_DELTAZ_DEPTH = 0x0126
    case GPUREG_FRAGOP_SHADOW = 0x0130
    case GPUREG_LIGHT0_SPECULAR0 = 0x0140
    case GPUREG_LIGHT0_SPECULAR1 = 0x0141
    case GPUREG_LIGHT0_DIFFUSE = 0x0142
    case GPUREG_LIGHT0_AMBIENT = 0x0143
    case GPUREG_LIGHT0_XY = 0x0144
    case GPUREG_LIGHT0_Z = 0x0145
    case GPUREG_LIGHT0_SPOTDIR_XY = 0x0146
    case GPUREG_LIGHT0_SPOTDIR_Z = 0x0147
    case GPUREG_LIGHT0_CONFIG = 0x0149
    case GPUREG_LIGHT0_ATTENUATION_BIAS = 0x014A
    case GPUREG_LIGHT0_ATTENUATION_SCALE = 0x014B
    case GPUREG_LIGHT1_SPECULAR0 = 0x0150
    case GPUREG_LIGHT1_SPECULAR1 = 0x0151
    case GPUREG_LIGHT1_DIFFUSE = 0x0152
    case GPUREG_LIGHT1_AMBIENT = 0x0153
    case GPUREG_LIGHT1_XY = 0x0154
    case GPUREG_LIGHT1_Z = 0x0155
    case GPUREG_LIGHT1_SPOTDIR_XY = 0x0156
    case GPUREG_LIGHT1_SPOTDIR_Z = 0x0157
    case GPUREG_LIGHT1_CONFIG = 0x0159
    case GPUREG_LIGHT1_ATTENUATION_BIAS = 0x015A
    case GPUREG_LIGHT1_ATTENUATION_SCALE = 0x015B
    case GPUREG_LIGHT2_SPECULAR0 = 0x0160
    case GPUREG_LIGHT2_SPECULAR1 = 0x0161
    case GPUREG_LIGHT2_DIFFUSE = 0x0162
    case GPUREG_LIGHT2_AMBIENT = 0x0163
    case GPUREG_LIGHT2_XY = 0x0164
    case GPUREG_LIGHT2_Z = 0x0165
    case GPUREG_LIGHT2_SPOTDIR_XY = 0x0166
    case GPUREG_LIGHT2_SPOTDIR_Z = 0x0167
    case GPUREG_LIGHT2_CONFIG = 0x0169
    case GPUREG_LIGHT2_ATTENUATION_BIAS = 0x016A
    case GPUREG_LIGHT2_ATTENUATION_SCALE = 0x016B
    case GPUREG_LIGHT3_SPECULAR0 = 0x0170
    case GPUREG_LIGHT3_SPECULAR1 = 0x0171
    case GPUREG_LIGHT3_DIFFUSE = 0x0172
    case GPUREG_LIGHT3_AMBIENT = 0x0173
    case GPUREG_LIGHT3_XY = 0x0174
    case GPUREG_LIGHT3_Z = 0x0175
    case GPUREG_LIGHT3_SPOTDIR_XY = 0x0176
    case GPUREG_LIGHT3_SPOTDIR_Z = 0x0177
    case GPUREG_LIGHT3_CONFIG = 0x0179
    case GPUREG_LIGHT3_ATTENUATION_BIAS = 0x017A
    case GPUREG_LIGHT3_ATTENUATION_SCALE = 0x017B
    case GPUREG_LIGHT4_SPECULAR0 = 0x0180
    case GPUREG_LIGHT4_SPECULAR1 = 0x0181
    case GPUREG_LIGHT4_DIFFUSE = 0x0182
    case GPUREG_LIGHT4_AMBIENT = 0x0183
    case GPUREG_LIGHT4_XY = 0x0184
    case GPUREG_LIGHT4_Z = 0x0185
    case GPUREG_LIGHT4_SPOTDIR_XY = 0x0186
    case GPUREG_LIGHT4_SPOTDIR_Z = 0x0187
    case GPUREG_LIGHT4_CONFIG = 0x0189
    case GPUREG_LIGHT4_ATTENUATION_BIAS = 0x018A
    case GPUREG_LIGHT4_ATTENUATION_SCALE = 0x018B
    case GPUREG_LIGHT5_SPECULAR0 = 0x0190
    case GPUREG_LIGHT5_SPECULAR1 = 0x0191
    case GPUREG_LIGHT5_DIFFUSE = 0x0192
    case GPUREG_LIGHT5_AMBIENT = 0x0193
    case GPUREG_LIGHT5_XY = 0x0194
    case GPUREG_LIGHT5_Z = 0x0195
    case GPUREG_LIGHT5_SPOTDIR_XY = 0x0196
    case GPUREG_LIGHT5_SPOTDIR_Z = 0x0197
    case GPUREG_LIGHT5_CONFIG = 0x0199
    case GPUREG_LIGHT5_ATTENUATION_BIAS = 0x019A
    case GPUREG_LIGHT5_ATTENUATION_SCALE = 0x019B
    case GPUREG_LIGHT6_SPECULAR0 = 0x01A0
    case GPUREG_LIGHT6_SPECULAR1 = 0x01A1
    case GPUREG_LIGHT6_DIFFUSE = 0x01A2
    case GPUREG_LIGHT6_AMBIENT = 0x01A3
    case GPUREG_LIGHT6_XY = 0x01A4
    case GPUREG_LIGHT6_Z = 0x01A5
    case GPUREG_LIGHT6_SPOTDIR_XY = 0x01A6
    case GPUREG_LIGHT6_SPOTDIR_Z = 0x01A7
    case GPUREG_LIGHT6_CONFIG = 0x01A9
    case GPUREG_LIGHT6_ATTENUATION_BIAS = 0x01AA
    case GPUREG_LIGHT6_ATTENUATION_SCALE = 0x01AB
    case GPUREG_LIGHT7_SPECULAR0 = 0x01B0
    case GPUREG_LIGHT7_SPECULAR1 = 0x01B1
    case GPUREG_LIGHT7_DIFFUSE = 0x01B2
    case GPUREG_LIGHT7_AMBIENT = 0x01B3
    case GPUREG_LIGHT7_XY = 0x01B4
    case GPUREG_LIGHT7_Z = 0x01B5
    case GPUREG_LIGHT7_SPOTDIR_XY = 0x01B6
    case GPUREG_LIGHT7_SPOTDIR_Z = 0x01B7
    case GPUREG_LIGHT7_CONFIG = 0x01B9
    case GPUREG_LIGHT7_ATTENUATION_BIAS = 0x01BA
    case GPUREG_LIGHT7_ATTENUATION_SCALE = 0x01BB
    case GPUREG_LIGHTING_AMBIENT = 0x01C0
    case GPUREG_LIGHTING_NUM_LIGHTS = 0x01C2
    case GPUREG_LIGHTING_CONFIG0 = 0x01C3
    case GPUREG_LIGHTING_CONFIG1 = 0x01C4
    case GPUREG_LIGHTING_LUT_INDEX = 0x01C5
    case GPUREG_LIGHTING_ENABLE1 = 0x01C6
    case GPUREG_LIGHTING_LUT_DATA0 = 0x01C8
    case GPUREG_LIGHTING_LUT_DATA1 = 0x01C9
    case GPUREG_LIGHTING_LUT_DATA2 = 0x01CA
    case GPUREG_LIGHTING_LUT_DATA3 = 0x01CB
    case GPUREG_LIGHTING_LUT_DATA4 = 0x01CC
    case GPUREG_LIGHTING_LUT_DATA5 = 0x01CD
    case GPUREG_LIGHTING_LUT_DATA6 = 0x01CE
    case GPUREG_LIGHTING_LUT_DATA7 = 0x01CF
    case GPUREG_LIGHTING_LUTINPUT_ABS = 0x01D0
    case GPUREG_LIGHTING_LUTINPUT_SELECT = 0x01D1
    case GPUREG_LIGHTING_LUTINPUT_SCALE = 0x01D2
    case GPUREG_LIGHTING_LIGHT_PERMUTATION = 0x01D9
    case GPUREG_ATTRIBBUFFERS_LOC = 0x0200
    case GPUREG_ATTRIBBUFFERS_FORMAT_LOW = 0x0201
    case GPUREG_ATTRIBBUFFERS_FORMAT_HIGH = 0x0202
    case GPUREG_ATTRIBBUFFER0_OFFSET = 0x0203
    case GPUREG_ATTRIBBUFFER0_CONFIG1 = 0x0204
    case GPUREG_ATTRIBBUFFER0_CONFIG2 = 0x0205
    case GPUREG_ATTRIBBUFFER1_OFFSET = 0x0206
    case GPUREG_ATTRIBBUFFER1_CONFIG1 = 0x0207
    case GPUREG_ATTRIBBUFFER1_CONFIG2 = 0x0208
    case GPUREG_ATTRIBBUFFER2_OFFSET = 0x0209
    case GPUREG_ATTRIBBUFFER2_CONFIG1 = 0x020A
    case GPUREG_ATTRIBBUFFER2_CONFIG2 = 0x020B
    case GPUREG_ATTRIBBUFFER3_OFFSET = 0x020C
    case GPUREG_ATTRIBBUFFER3_CONFIG1 = 0x020D
    case GPUREG_ATTRIBBUFFER3_CONFIG2 = 0x020E
    case GPUREG_ATTRIBBUFFER4_OFFSET = 0x020F
    case GPUREG_ATTRIBBUFFER4_CONFIG1 = 0x0210
    case GPUREG_ATTRIBBUFFER4_CONFIG2 = 0x0211
    case GPUREG_ATTRIBBUFFER5_OFFSET = 0x0212
    case GPUREG_ATTRIBBUFFER5_CONFIG1 = 0x0213
    case GPUREG_ATTRIBBUFFER5_CONFIG2 = 0x0214
    case GPUREG_ATTRIBBUFFER6_OFFSET = 0x0215
    case GPUREG_ATTRIBBUFFER6_CONFIG1 = 0x0216
    case GPUREG_ATTRIBBUFFER6_CONFIG2 = 0x0217
    case GPUREG_ATTRIBBUFFER7_OFFSET = 0x0218
    case GPUREG_ATTRIBBUFFER7_CONFIG1 = 0x0219
    case GPUREG_ATTRIBBUFFER7_CONFIG2 = 0x021A
    case GPUREG_ATTRIBBUFFER8_OFFSET = 0x021B
    case GPUREG_ATTRIBBUFFER8_CONFIG1 = 0x021C
    case GPUREG_ATTRIBBUFFER8_CONFIG2 = 0x021D
    case GPUREG_ATTRIBBUFFER9_OFFSET = 0x021E
    case GPUREG_ATTRIBBUFFER9_CONFIG1 = 0x021F
    case GPUREG_ATTRIBBUFFER9_CONFIG2 = 0x0220
    case GPUREG_ATTRIBBUFFER10_OFFSET = 0x0221
    case GPUREG_ATTRIBBUFFER10_CONFIG1 = 0x0222
    case GPUREG_ATTRIBBUFFER10_CONFIG2 = 0x0223
    case GPUREG_ATTRIBBUFFER11_OFFSET = 0x0224
    case GPUREG_ATTRIBBUFFER11_CONFIG1 = 0x0225
    case GPUREG_ATTRIBBUFFER11_CONFIG2 = 0x0226
    case GPUREG_INDEXBUFFER_CONFIG = 0x0227
    case GPUREG_NUMVERTICES = 0x0228
    case GPUREG_GEOSTAGE_CONFIG = 0x0229
    case GPUREG_VERTEX_OFFSET = 0x022A
    case GPUREG_POST_VERTEX_CACHE_NUM = 0x022D
    case GPUREG_DRAWARRAYS = 0x022E
    case GPUREG_DRAWELEMENTS = 0x022F
    case GPUREG_VTX_FUNC = 0x0231
    case GPUREG_FIXEDATTRIB_INDEX = 0x0232
    case GPUREG_FIXEDATTRIB_DATA0 = 0x0233
    case GPUREG_FIXEDATTRIB_DATA1 = 0x0234
    case GPUREG_FIXEDATTRIB_DATA2 = 0x0235
    case GPUREG_CMDBUF_SIZE0 = 0x0238
    case GPUREG_CMDBUF_SIZE1 = 0x0239
    case GPUREG_CMDBUF_ADDR0 = 0x023A
    case GPUREG_CMDBUF_ADDR1 = 0x023B
    case GPUREG_CMDBUF_JUMP0 = 0x023C
    case GPUREG_CMDBUF_JUMP1 = 0x023D
    case GPUREG_VSH_NUM_ATTR = 0x0242
    case GPUREG_VSH_COM_MODE = 0x0244
    case GPUREG_START_DRAW_FUNC0 = 0x0245
    case GPUREG_VSH_OUTMAP_TOTAL1 = 0x024A
    case GPUREG_VSH_OUTMAP_TOTAL2 = 0x0251
    case GPUREG_GSH_MISC0 = 0x0252
    case GPUREG_GEOSTAGE_CONFIG2 = 0x0253
    case GPUREG_GSH_MISC1 = 0x0254
    case GPUREG_PRIMITIVE_CONFIG = 0x025E
    case GPUREG_RESTART_PRIMITIVE = 0x025F
    case GPUREG_GSH_BOOLUNIFORM = 0x0280
    case GPUREG_GSH_INTUNIFORM_I0 = 0x0281
    case GPUREG_GSH_INTUNIFORM_I1 = 0x0282
    case GPUREG_GSH_INTUNIFORM_I2 = 0x0283
    case GPUREG_GSH_INTUNIFORM_I3 = 0x0284
    case GPUREG_GSH_INPUTBUFFER_CONFIG = 0x0289
    case GPUREG_GSH_ENTRYPOINT = 0x028A
    case GPUREG_GSH_ATTRIBUTES_PERMUTATION_LOW = 0x028B
    case GPUREG_GSH_ATTRIBUTES_PERMUTATION_HIGH = 0x028C
    case GPUREG_GSH_OUTMAP_MASK = 0x028D
    case GPUREG_GSH_CODETRANSFER_END = 0x028F
    case GPUREG_GSH_FLOATUNIFORM_INDEX = 0x0290
    case GPUREG_GSH_FLOATUNIFORM_DATA0 = 0x0291
    case GPUREG_GSH_FLOATUNIFORM_DATA1 = 0x0292
    case GPUREG_GSH_FLOATUNIFORM_DATA2 = 0x0293
    case GPUREG_GSH_FLOATUNIFORM_DATA3 = 0x0294
    case GPUREG_GSH_FLOATUNIFORM_DATA4 = 0x0295
    case GPUREG_GSH_FLOATUNIFORM_DATA5 = 0x0296
    case GPUREG_GSH_FLOATUNIFORM_DATA6 = 0x0297
    case GPUREG_GSH_FLOATUNIFORM_DATA7 = 0x0298
    case GPUREG_GSH_CODETRANSFER_INDEX = 0x029B
    case GPUREG_GSH_CODETRANSFER_DATA0 = 0x029C
    case GPUREG_GSH_CODETRANSFER_DATA1 = 0x029D
    case GPUREG_GSH_CODETRANSFER_DATA2 = 0x029E
    case GPUREG_GSH_CODETRANSFER_DATA3 = 0x029F
    case GPUREG_GSH_CODETRANSFER_DATA4 = 0x02A0
    case GPUREG_GSH_CODETRANSFER_DATA5 = 0x02A1
    case GPUREG_GSH_CODETRANSFER_DATA6 = 0x02A2
    case GPUREG_GSH_CODETRANSFER_DATA7 = 0x02A3
    case GPUREG_GSH_OPDESCS_INDEX = 0x02A5
    case GPUREG_GSH_OPDESCS_DATA0 = 0x02A6
    case GPUREG_GSH_OPDESCS_DATA1 = 0x02A7
    case GPUREG_GSH_OPDESCS_DATA2 = 0x02A8
    case GPUREG_GSH_OPDESCS_DATA3 = 0x02A9
    case GPUREG_GSH_OPDESCS_DATA4 = 0x02AA
    case GPUREG_GSH_OPDESCS_DATA5 = 0x02AB
    case GPUREG_GSH_OPDESCS_DATA6 = 0x02AC
    case GPUREG_GSH_OPDESCS_DATA7 = 0x02AD
    case GPUREG_VSH_BOOLUNIFORM = 0x02B0
    case GPUREG_VSH_INTUNIFORM_I0 = 0x02B1
    case GPUREG_VSH_INTUNIFORM_I1 = 0x02B2
    case GPUREG_VSH_INTUNIFORM_I2 = 0x02B3
    case GPUREG_VSH_INTUNIFORM_I3 = 0x02B4
    case GPUREG_VSH_INPUTBUFFER_CONFIG = 0x02B9
    case GPUREG_VSH_ENTRYPOINT = 0x02BA
    case GPUREG_VSH_ATTRIBUTES_PERMUTATION_LOW = 0x02BB
    case GPUREG_VSH_ATTRIBUTES_PERMUTATION_HIGH = 0x02BC
    case GPUREG_VSH_OUTMAP_MASK = 0x02BD
    case GPUREG_VSH_CODETRANSFER_END = 0x02BF
    case GPUREG_VSH_FLOATUNIFORM_INDEX = 0x02C0
    case GPUREG_VSH_FLOATUNIFORM_DATA0 = 0x02C1
    case GPUREG_VSH_FLOATUNIFORM_DATA1 = 0x02C2
    case GPUREG_VSH_FLOATUNIFORM_DATA2 = 0x02C3
    case GPUREG_VSH_FLOATUNIFORM_DATA3 = 0x02C4
    case GPUREG_VSH_FLOATUNIFORM_DATA4 = 0x02C5
    case GPUREG_VSH_FLOATUNIFORM_DATA5 = 0x02C6
    case GPUREG_VSH_FLOATUNIFORM_DATA6 = 0x02C7
    case GPUREG_VSH_FLOATUNIFORM_DATA7 = 0x02C8
    case GPUREG_VSH_CODETRANSFER_INDEX = 0x02CB
    case GPUREG_VSH_CODETRANSFER_DATA0 = 0x02CC
    case GPUREG_VSH_CODETRANSFER_DATA1 = 0x02CD
    case GPUREG_VSH_CODETRANSFER_DATA2 = 0x02CE
    case GPUREG_VSH_CODETRANSFER_DATA3 = 0x02CF
    case GPUREG_VSH_CODETRANSFER_DATA4 = 0x02D0
    case GPUREG_VSH_CODETRANSFER_DATA5 = 0x02D1
    case GPUREG_VSH_CODETRANSFER_DATA6 = 0x02D2
    case GPUREG_VSH_CODETRANSFER_DATA7 = 0x02D3
    case GPUREG_VSH_OPDESCS_INDEX = 0x02D5
    case GPUREG_VSH_OPDESCS_DATA0 = 0x02D6
    case GPUREG_VSH_OPDESCS_DATA1 = 0x02D7
    case GPUREG_VSH_OPDESCS_DATA2 = 0x02D8
    case GPUREG_VSH_OPDESCS_DATA3 = 0x02D9
    case GPUREG_VSH_OPDESCS_DATA4 = 0x02DA
    case GPUREG_VSH_OPDESCS_DATA5 = 0x02DB
    case GPUREG_VSH_OPDESCS_DATA6 = 0x02DC
    case GPUREG_VSH_OPDESCS_DATA7 = 0x02DD
    
}
