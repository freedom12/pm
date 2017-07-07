//
//  SubMesh.swift
//  pm
//
//  Created by wanghuai on 2017/6/20.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
import Metal

class SubMesh {
    unowned var parent:Mesh
    var material:Material! = nil
    var materialName = ""
    
    var vertBuffer:MTLBuffer! = nil
    var indexBuffer:MTLBuffer! = nil
    var renderPipelineState: MTLRenderPipelineState! = nil
    var depthStencilState:MTLDepthStencilState! = nil
    
    var indexCount = 0
    var indexType:MTLIndexType = .uint16
    
    var boneIndices:[Int] = []
    
    var fixedBoneIndex = Vector4.zero
    var fixedBoneWeight = Vector4.zero
    
    
    var isVisible = false
    init(gfSubMesh: GFSubMesh, to mesh:Mesh) {
        parent = mesh
        materialName = gfSubMesh.name
        material = parent.parent.materialDict[gfSubMesh.name]!
        boneIndices = gfSubMesh.boneIndices
        
        let device = RenderEngine.sharedInstance.device!
        let vertDesc = MTLVertexDescriptor.init()
        
        let bufferIndex = 0
        var index = 0
        var offset = 0
        
        var hasTexcoord0 = false
        var hasBoneIndex = false
        var hasBoneWeigth = false
        
        for attr in gfSubMesh.attrs {
            let type = attr.formate
            let num = attr.elements
            if attr.name == .position {
                vertDesc.attributes[0].format = .float3
                vertDesc.attributes[0].offset = offset
                vertDesc.attributes[0].bufferIndex = bufferIndex
            } else if attr.name == .texCoord0 {
                vertDesc.attributes[1].format = .float2
                vertDesc.attributes[1].offset = offset
                vertDesc.attributes[1].bufferIndex = bufferIndex
                hasTexcoord0 = true
//            } else if attr.name == .texCoord1 {
//                vertDesc.attributes[2].format = .float2
//                vertDesc.attributes[2].offset = offset
//                vertDesc.attributes[2].bufferIndex = bufferIndex
//            } else if attr.name == .texCoord2 {
//                vertDesc.attributes[3].format = .float2
//                vertDesc.attributes[3].offset = offset
//                vertDesc.attributes[3].bufferIndex = bufferIndex
            } else if attr.name == .boneIndex {
                vertDesc.attributes[2].format = .uchar4
                vertDesc.attributes[2].offset = offset
                vertDesc.attributes[2].bufferIndex = bufferIndex
                hasBoneIndex = true
            } else if attr.name == .boneWeight {
                vertDesc.attributes[3].format = .uchar4Normalized
                vertDesc.attributes[3].offset = offset
                vertDesc.attributes[3].bufferIndex = bufferIndex
                hasBoneWeigth = true
            }
            
            
            if (type == .byte && num == 1) {
//                vertDescriptor.attributes[index].format = .char
                offset = offset + 1
            } else if (type == .byte && num == 2) {
//                vertDescriptor.attributes[index].format = .char2
                offset = offset + 2
            } else if (type == .byte && num == 3) {
//                vertDescriptor.attributes[index].format = .char3
                offset = offset + 3
            } else if (type == .byte && num == 4) {
//                vertDescriptor.attributes[index].format = .char4
                offset = offset + 4
            } else if (type == .uByte && num == 1) {
//                vertDescriptor.attributes[index].format = .uchar
                offset = offset + 1
            } else if (type == .uByte && num == 2) {
//                vertDescriptor.attributes[index].format = .uchar2
                offset = offset + 2
            } else if (type == .uByte && num == 3) {
//                vertDescriptor.attributes[index].format = .uchar3
                offset = offset + 3
            } else if (type == .uByte && num == 4) {
//                vertDescriptor.attributes[index].format = .uchar4
                offset = offset + 4
            } else if (type == .short && num == 1) {
//                vertDescriptor.attributes[index].format = .short
                offset = offset + 2
            } else if (type == .short && num == 2) {
//                vertDescriptor.attributes[index].format = .short2
                offset = offset + 4
            } else if (type == .short && num == 3) {
//                vertDescriptor.attributes[index].format = .short3
                offset = offset + 6
            } else if (type == .short && num == 4) {
//                vertDescriptor.attributes[index].format = .short4
                offset = offset + 8
            } else if (type == .float && num == 1) {
//                vertDescriptor.attributes[index].format = .float
                offset = offset + 4
            } else if (type == .float && num == 2) {
//                vertDescriptor.attributes[index].format = .float2
                offset = offset + 8
            } else if (type == .float && num == 3) {
//                vertDescriptor.attributes[index].format = .float3
                offset = offset + 12
            } else if (type == .float && num == 4) {
//                vertDescriptor.attributes[index].format = .float4
                offset = offset + 16
            }
            
            index += 1
        }
        
        for attr in gfSubMesh.fixedAttrs {
            if attr.name == .position {
                
            } else if attr.name == .texCoord0 {
                
            } else if attr.name == .boneIndex {
                fixedBoneIndex = attr.value
            } else if attr.name == .boneWeight {
                fixedBoneWeight = attr.value
            }
        }
        isVisible = true
        
        vertDesc.layouts[bufferIndex].stride = offset
        vertDesc.layouts[bufferIndex].stepRate = 1
        vertDesc.layouts[bufferIndex].stepFunction = .perVertex
        
        vertBuffer = device.makeBuffer(bytes: gfSubMesh.rawBuffer.bytes, length: gfSubMesh.rawBuffer.length, options: [])
        vertBuffer.label = gfSubMesh.name
        
        var tmp:[UInt16] = []
        for index in gfSubMesh.indices {
            tmp.append(UInt16(index))
        }
        
        indexBuffer = device.makeBuffer(bytes: tmp, length: tmp.count*MemoryLayout.size(ofValue: tmp[0]), options: [])
        indexBuffer.label = vertBuffer.label! + "_index"
        indexCount = tmp.count
        
        let colorDesc = MTLRenderPipelineColorAttachmentDescriptor.init()
        colorDesc.isBlendingEnabled = material.alphaBendEnable
        colorDesc.writeMask = material.colorWriteMask
        colorDesc.alphaBlendOperation = material.alphaBlendOpt
        colorDesc.rgbBlendOperation = material.colorBlendOpt
        colorDesc.destinationAlphaBlendFactor = material.alphaDesFactor
        colorDesc.destinationRGBBlendFactor = material.colorDesFactor
        colorDesc.sourceAlphaBlendFactor = material.alphaSrcFactor
        colorDesc.sourceRGBBlendFactor = material.colorSrcFactor
        colorDesc.pixelFormat = .bgra8Unorm
        
        let renderPiplineDesc = MTLRenderPipelineDescriptor.init()
        renderPiplineDesc.vertexFunction = RenderEngine.sharedInstance.vertFunc
        renderPiplineDesc.fragmentFunction = RenderEngine.sharedInstance.fragFunc
        renderPiplineDesc.vertexDescriptor = vertDesc
        renderPiplineDesc.colorAttachments[0] = colorDesc
        renderPiplineDesc.depthAttachmentPixelFormat = .depth32Float_stencil8
        renderPiplineDesc.stencilAttachmentPixelFormat = .depth32Float_stencil8
        
        if hasBoneWeigth && hasBoneIndex && hasTexcoord0
        {
            renderPiplineDesc.vertexFunction = RenderEngine.sharedInstance.vertFunc_t0_bi_bw
            renderPiplineDesc.fragmentFunction = RenderEngine.sharedInstance.fragFunc_t0
        } else if hasBoneIndex && hasTexcoord0 {
            renderPiplineDesc.vertexFunction = RenderEngine.sharedInstance.vertFunc_t0_bi
            renderPiplineDesc.fragmentFunction = RenderEngine.sharedInstance.fragFunc_t0
        } else if hasBoneWeigth && hasTexcoord0 {
            renderPiplineDesc.vertexFunction = RenderEngine.sharedInstance.vertFunc_t0_bw
            renderPiplineDesc.fragmentFunction = RenderEngine.sharedInstance.fragFunc_t0
        } else if hasTexcoord0 {
            renderPiplineDesc.vertexFunction = RenderEngine.sharedInstance.vertFunc_t0
            renderPiplineDesc.fragmentFunction = RenderEngine.sharedInstance.fragFunc_t0
        }
        
        let stencilDesc = MTLStencilDescriptor.init()
        stencilDesc.readMask = material.stencilReadMask
        stencilDesc.writeMask = material.stencilWriteMask
        stencilDesc.stencilCompareFunction = material.stencilCompareFunc
        stencilDesc.stencilFailureOperation = material.stencilFailOpt
        stencilDesc.depthFailureOperation = material.depthFailOpt
        stencilDesc.depthStencilPassOperation = material.depthStencilPassOpt
        
        let depthStencilDesc = MTLDepthStencilDescriptor.init()
        
        if material.depthTestEnable {
            depthStencilDesc.isDepthWriteEnabled = material.depthWriteMask
            depthStencilDesc.depthCompareFunction = material.depthCompareFunc
        }
        
        if material.stencilTestEnable {
            depthStencilDesc.frontFaceStencil = stencilDesc
            depthStencilDesc.backFaceStencil = stencilDesc
        }
        
        do {
            try renderPipelineState = device.makeRenderPipelineState(descriptor: renderPiplineDesc)
            depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDesc)
        } catch {
            print("创建pipeline state失败： \(error)")
        }
    }
}

