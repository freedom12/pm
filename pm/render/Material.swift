//
//  Meterial.swift
//  pm
//
//  Created by wanghuai on 2017/6/21.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
import Metal

class Material {
    var device:MTLDevice! = nil
    var name = ""
    var textureNames:[String] = []
    var samplerStates:[MTLSamplerState] = []
    
    var alphaBendEnable = false
    var colorWriteMask:MTLColorWriteMask = .all
    var alphaBlendOpt:MTLBlendOperation = .add
    var colorBlendOpt:MTLBlendOperation = .add
    var alphaDesFactor:MTLBlendFactor = .one
    var colorDesFactor:MTLBlendFactor = .one
    var alphaSrcFactor:MTLBlendFactor = .one
    var colorSrcFactor:MTLBlendFactor = .one
    
    var stencilReadMask:UInt32 = 0
    var stencilWriteMask:UInt32 = 0
    var stencilCompareFunc:MTLCompareFunction = .always
    var stencilFailOpt:MTLStencilOperation = .keep
    var depthFailOpt:MTLStencilOperation = .keep
    var depthStencilPassOpt:MTLStencilOperation = .keep
    
    var depthWriteMask = false
    var depthCompareFunc:MTLCompareFunction = .always
    
    var cullMode:MTLCullMode = .none
    var stencilReference:UInt32 = 0
    init(device _device:MTLDevice, gfMaterial:GFMaterial){
        device = _device
        
        name = gfMaterial.name
        
        for sampler in gfMaterial.samplers {
            let textureName = sampler.name
            textureNames.append(textureName)
            
            let desc = MTLSamplerDescriptor.init()
            desc.minFilter = sampler.minFilter.to()
            desc.magFilter = sampler.magFilter.to()
            desc.sAddressMode = sampler.wrapU.to()
            desc.tAddressMode = sampler.wrapV.to()
            desc.lodMinClamp = Float(sampler.minLOD)
            let samplerState = device.makeSamplerState(descriptor: desc)!
            samplerStates.append(samplerState)
        }
        
        alphaBendEnable = (gfMaterial.colorOpt.blendMode == .blend)
        colorWriteMask = gfMaterial.depthColorMask.getWriteMask()
        alphaBlendOpt = gfMaterial.blend.alphaOPt.to()
        colorBlendOpt = gfMaterial.blend.colorOpt.to()
        alphaDesFactor = gfMaterial.blend.alphaDstFunc.to()
        colorDesFactor = gfMaterial.blend.colorDstFunc.to()
        alphaSrcFactor = gfMaterial.blend.alphaSrcFunc.to()
        colorSrcFactor = gfMaterial.blend.colorSrcFunc.to()
        
        stencilReadMask = UInt32(gfMaterial.stencilTest.mask)
        stencilWriteMask = UInt32(gfMaterial.stencilTest.bufferMask)
        stencilCompareFunc = gfMaterial.stencilTest.testFunc.to()
        stencilFailOpt = gfMaterial.stencilOpt.failOpt.to()
        depthFailOpt = gfMaterial.stencilOpt.zFailOpt.to()
        depthStencilPassOpt = gfMaterial.stencilOpt.zPassOpt.to()
        
        depthCompareFunc = gfMaterial.depthColorMask.depthFunc.to()
        depthWriteMask = gfMaterial.depthColorMask.depthWrite
        
        cullMode = gfMaterial.faceCulling.to()
        stencilReference = UInt32(gfMaterial.stencilTest.reference)
        
    }
}
