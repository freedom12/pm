//
//  PICAEnum.swift
//  pm
//
//  Created by wanghuai on 2017/6/22.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
import Metal


enum PICAFragMode:Int {
    case defaut = 0
    case gas
    case shadow
}

enum PICABlendMode:Int {
    case logical = 0
    case blend
}

enum PICABlenOpt:Int {
    case funcAdd = 0
    case funcSub
    case funcReverseSub
    case min
    case max
    
    func to() -> MTLBlendOperation {
        switch self {
        case .funcAdd: return MTLBlendOperation.add
        case .funcSub: return MTLBlendOperation.subtract
        case .funcReverseSub: return  MTLBlendOperation.reverseSubtract
        case .min: return MTLBlendOperation.min
        case .max: return MTLBlendOperation.max
        }
    }
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
    
    func to() -> MTLBlendFactor {
        switch self {
        case .zero: return MTLBlendFactor.zero
        case .one: return MTLBlendFactor.one
        case .srcColor: return MTLBlendFactor.sourceColor
        case .oneMinusSrcColor: return MTLBlendFactor.oneMinusSourceColor
        case .dstColor: return MTLBlendFactor.destinationColor
        case .oneMinusDesColor: return MTLBlendFactor.oneMinusDestinationColor
        case .srcAlpha: return MTLBlendFactor.sourceAlpha
        case .oneMinusSrcAlpha: return MTLBlendFactor.oneMinusSourceAlpha
        case .dstAlpha: return MTLBlendFactor.destinationAlpha
        case .oneMinusDstAlpha: return MTLBlendFactor.oneMinusDestinationAlpha
        case .constColor: return MTLBlendFactor.source1Color
        case .oneMinusConstColor: return MTLBlendFactor.oneMinusSource1Color
        case .constAlpha: return MTLBlendFactor.source1Alpha
        case .oneMinusConstAlpha: return MTLBlendFactor.oneMinusSource1Alpha
        case .srcAlphaSaturate: return MTLBlendFactor.sourceAlphaSaturated
        }
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
    
    func to() -> MTLCompareFunction {
        switch self {
        case .never: return MTLCompareFunction.never
        case .always: return MTLCompareFunction.always
        case .equal: return MTLCompareFunction.equal
        case .notEqual: return MTLCompareFunction.notEqual
        case .less: return MTLCompareFunction.less
        case .lessEqual: return MTLCompareFunction.lessEqual
        case .greater: return MTLCompareFunction.greater
        case .greaterEqual: return MTLCompareFunction.greaterEqual
        }
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
    
    func to() -> MTLStencilOperation {
        switch self {
        case .keep: return MTLStencilOperation.keep
        case .zero: return MTLStencilOperation.zero
        case .replace: return MTLStencilOperation.replace
        case .inc: return MTLStencilOperation.decrementClamp
        case .dec: return MTLStencilOperation.decrementClamp
        case .invert: return MTLStencilOperation.invert
        case .incWrap: return MTLStencilOperation.incrementWrap
        case .decWrap: return MTLStencilOperation.decrementWrap
        }
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

enum PICALutScale:Int {
    case one = 0
    case two = 1
    case four = 2
    case eight = 3
    case quarter = 6
    case half = 7
}

enum PICAAttrFormate:Int {
    case byte = 0
    case uByte
    case short
    case float
}

enum PICAAttrName:Int {
    case position = 0
    case normal
    case tangent
    case color
    case texCoord0
    case texCoord1
    case texCoord2
    case boneIndex
    case boneWeight
}

enum PICALogicalOpt:Int {
    case clear = 0
    case and
    case andReverse
    case copy
    case set
    case copyInverted
    case noop
    case invert
    case nand
    case or
    case nor
    case xor
    case equiv
    case andInverted
    case orReverse
    case orInverted
}

enum PICAFaceCulling:Int {
    case never = 0
    case front
    case back
    
    func to() -> MTLCullMode {
        switch self {
        case .never: return MTLCullMode.none
        case .front: return MTLCullMode.back
        case .back: return MTLCullMode.front
        }
    }
}

enum PICATextureCombinerSrc:Int {
    case primaryColor = 0
    case fragPrimaryColor
    case fragSecondaryColor
    case texture0
    case texture1
    case texture2
    case texture3
    case previousBuffer = 13
    case constant = 14
    case pervious = 15
}

enum PICATextureCombinerColorOp:Int {
    case color = 0
    case oneMinusColor
    case alpha
    case oneMinusAlpha
    case red
    case oneMinusRed
    case green = 8
    case oneMinusGreen = 9
    case blue = 12
    case oneMinusBlue = 13
}

enum PICATextureCombinerAlphaOp:Int {
    case alpha = 0
    case oneMinusAlpha
    case red
    case oneMinusRed
    case green
    case oneMinusGreen
    case blue
    case oneMinusBlue
}

enum PICATextureCombinerMode:Int {
    case replace = 0
    case modulate
    case add
    case addSigned
    case interpolate
    case subtract
    case dotProduct3RGB
    case dotProduct3RGBA
    case multAdd
    case addMult
}

enum PICATextureCombinerScale:Int {
    case one = 0
    case two
    case four
}

enum  PICATextureFormate:Int {
    case RGBA8 = 0
    case RGB8
    case RGBA5551
    case RGB565
    case RGBA4
    case LA8
    case HiLo8
    case L8
    case A8
    case LA4
    case L4
    case A4
    case ETC1
    case ETC1A4
}
