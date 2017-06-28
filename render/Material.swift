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
    var name = ""
    var textureNames:[String] = []
    var samplerStates:[MTLSamplerState] = []
    var transforms:[Matrix3] = []
    
    var alphaBendEnable = false
    var colorWriteMask:MTLColorWriteMask = .all
    var alphaBlendOpt:MTLBlendOperation = .add
    var colorBlendOpt:MTLBlendOperation = .add
    var alphaDesFactor:MTLBlendFactor = .one
    var colorDesFactor:MTLBlendFactor = .one
    var alphaSrcFactor:MTLBlendFactor = .one
    var colorSrcFactor:MTLBlendFactor = .one
    
    var stencilTestEnable = false
    var stencilReadMask:UInt32 = 0
    var stencilWriteMask:UInt32 = 0
    var stencilCompareFunc:MTLCompareFunction = .always
    var stencilFailOpt:MTLStencilOperation = .keep
    var depthFailOpt:MTLStencilOperation = .keep
    var depthStencilPassOpt:MTLStencilOperation = .keep
    
    var depthTestEnable = false
    var depthWriteMask = false
    var depthCompareFunc:MTLCompareFunction = .always
    
    var cullMode:MTLCullMode = .none
    var stencilReference:UInt32 = 0
    init(gfMaterial:GFMaterial){
        let device = RenderEngine.sharedInstance.device!
        
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
            transforms.append(sampler.transform)
        }
        
        alphaBendEnable = (gfMaterial.colorOpt.blendMode == .blend)
        colorWriteMask = gfMaterial.depthColorMask.getWriteMask()
        alphaBlendOpt = gfMaterial.blend.alphaOPt.to()
        colorBlendOpt = gfMaterial.blend.colorOpt.to()
        alphaDesFactor = gfMaterial.blend.alphaDstFunc.to()
        colorDesFactor = gfMaterial.blend.colorDstFunc.to()
        alphaSrcFactor = gfMaterial.blend.alphaSrcFunc.to()
        colorSrcFactor = gfMaterial.blend.colorSrcFunc.to()
        
        stencilTestEnable = gfMaterial.stencilTest.enable
        stencilReadMask = UInt32(gfMaterial.stencilTest.mask)
        stencilWriteMask = UInt32(gfMaterial.stencilTest.bufferMask)
        stencilCompareFunc = gfMaterial.stencilTest.testFunc.to()
        stencilFailOpt = gfMaterial.stencilOpt.failOpt.to()
        depthFailOpt = gfMaterial.stencilOpt.zFailOpt.to()
        depthStencilPassOpt = gfMaterial.stencilOpt.zPassOpt.to()
        
        depthTestEnable = gfMaterial.depthColorMask.enable
        depthCompareFunc = gfMaterial.depthColorMask.depthFunc.to()
        depthWriteMask = gfMaterial.depthColorMask.depthWrite
        
        cullMode = gfMaterial.faceCulling.to()
        stencilReference = UInt32(gfMaterial.stencilTest.reference)
        
    }
}
