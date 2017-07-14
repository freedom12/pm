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
    var fixedAttrExists:[Bool] = Array.init(repeating: false, count: 9)
    var fixedAttrs:[Vector4] = Array.init(repeating: Vector4.zero, count: 9)
    
    var isVisible = false
    init(gfSubMesh: GFSubMesh, to mesh:Mesh) {
        parent = mesh
        materialName = gfSubMesh.name
        material = parent.parent.materialDict[gfSubMesh.name]!
        boneIndices = gfSubMesh.boneIndices
        
        let device = RenderEngine.sharedInstance.device!
        let vertDesc = MTLVertexDescriptor.init()
        
        let bufferIndex = 0
        var offset = 0
        
        for attr in gfSubMesh.attrs {
            let type = attr.formate
            let num = attr.elements
            let pos = attr.name.rawValue
            if attr.name == .position {
                vertDesc.attributes[pos].format = .float3
            } else if attr.name == .texCoord0 {
                vertDesc.attributes[pos].format = .float2
            } else if attr.name == .texCoord1 {
                vertDesc.attributes[pos].format = .float2
            } else if attr.name == .texCoord2 {
                vertDesc.attributes[pos].format = .float2
            } else if attr.name == .boneIndex {
                vertDesc.attributes[pos].format = .uchar4
            } else if attr.name == .boneWeight {
                vertDesc.attributes[pos].format = .uchar4Normalized
            }
            vertDesc.attributes[pos].offset = offset
            vertDesc.attributes[pos].bufferIndex = bufferIndex
            
            if (type == .byte || type == .uByte) {
                offset = offset + 1 * num
            } else if (type == .short) {
                offset = offset + 2 * num
            } else if (type == .float) {
                offset = offset + 4 * num
            }
        }
        
        for attr in gfSubMesh.fixedAttrs {
            fixedAttrs[attr.name.rawValue] = attr.value
            fixedAttrExists[attr.name.rawValue] = true
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
        (renderPiplineDesc.vertexFunction, renderPiplineDesc.fragmentFunction) = createFunc()
        renderPiplineDesc.vertexDescriptor = vertDesc
        renderPiplineDesc.colorAttachments[0] = colorDesc
        renderPiplineDesc.depthAttachmentPixelFormat = .depth32Float_stencil8
        renderPiplineDesc.stencilAttachmentPixelFormat = .depth32Float_stencil8
        
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
    
    private func createFunc() -> (MTLFunction?, MTLFunction?) {
        var str = "#include <metal_stdlib>\n"
        str += "using namespace metal;\n"
        str += "struct Vin {\n"
        str += "    float3 translation [[attribute(\(PICAAttrName.position.rawValue))]];\n"
        if !fixedAttrExists[PICAAttrName.texCoord0.rawValue] {
            str += "    float2 texcoord0 [[attribute(\(PICAAttrName.texCoord0.rawValue))]];\n"
        }
        if !fixedAttrExists[PICAAttrName.texCoord1.rawValue] {
            str += "    float2 texcoord1 [[attribute(\(PICAAttrName.texCoord1.rawValue))]];\n"
        }
        if !fixedAttrExists[PICAAttrName.texCoord2.rawValue] {
            str += "    float2 texcoord2 [[attribute(\(PICAAttrName.texCoord2.rawValue))]];\n"
        }
        if !fixedAttrExists[PICAAttrName.boneIndex.rawValue] {
            str += "    uchar4 boneIndex [[attribute(\(PICAAttrName.boneIndex.rawValue))]];\n"
        }
        if !fixedAttrExists[PICAAttrName.boneWeight.rawValue] {
            str += "    float4 boneWeight [[attribute(\(PICAAttrName.boneWeight.rawValue))]];\n"
        }
        str += "};\n"
        
        str += "struct Vout {\n" +
        "    float4 translation [[position]];\n" +
        "    float2 texcoord0;\n" +
        "    float2 texcoord1;\n" +
        "    float2 texcoord2;\n" +
        "};\n"
        
        
        str += "vertex Vout vert_func (Vin in [[stage_in]],\n" +
            "       constant float4x4& projMat [[buffer(1)]],\n" +
            "       constant float4x4& mvMat [[buffer(2)]],\n" +
            "       constant packed_float3* matetialMatArr [[buffer(3)]],\n" +
            "       constant float4x4* animMatArr [[buffer(4)]],\n" +
            "       constant float4* fixedAttrArr [[buffer(10)]],\n" +
            "       unsigned int vid [[ vertex_id ]]) {\n" +
            "   Vout out;\n"
        if !fixedAttrExists[PICAAttrName.texCoord0.rawValue] {
            str += "    float2 texcoord0 = in.texcoord0;\n"
        } else {
            str += "    float2 texcoord0 = float2(0);\n"
            str += "    texcoord0.xy = fixedAttrArr[\(PICAAttrName.texCoord0.rawValue)].xy;\n"
        }
        if !fixedAttrExists[PICAAttrName.texCoord1.rawValue] {
            str += "    float2 texcoord1 = in.texcoord1;\n"
        } else {
            str += "    float2 texcoord1 = float2(0);\n"
            str += "    texcoord1.xy = fixedAttrArr[\(PICAAttrName.texCoord1.rawValue)].xy;\n"
        }
        if !fixedAttrExists[PICAAttrName.texCoord2.rawValue] {
            str += "    float2 texcoord2 = in.texcoord2;\n"
        } else {
            str += "    float2 texcoord2 = float2(0);\n"
            str += "    texcoord2.xy = fixedAttrArr[\(PICAAttrName.texCoord2.rawValue)].xy;\n"
        }
        if !fixedAttrExists[PICAAttrName.boneIndex.rawValue] {
            str += "    int4 boneIndex = (int4(in.boneIndex) & 0x1f);\n"
        } else {
            str += "    int4 boneIndex = int4(0);\n"
            str += "    boneIndex[0] = (int(fixedAttrArr[\(PICAAttrName.boneIndex.rawValue)][0]) & 0x1f);\n"
            str += "    boneIndex[1] = (int(fixedAttrArr[\(PICAAttrName.boneIndex.rawValue)][1]) & 0x1f);\n"
            str += "    boneIndex[2] = (int(fixedAttrArr[\(PICAAttrName.boneIndex.rawValue)][2]) & 0x1f);\n"
            str += "    boneIndex[3] = (int(fixedAttrArr[\(PICAAttrName.boneIndex.rawValue)][3]) & 0x1f);\n"
        }
        if !fixedAttrExists[PICAAttrName.boneWeight.rawValue] {
            str += "    float4 boneWeight = in.boneWeight;\n"
        } else {
            str += "    float4 boneWeight = fixedAttrArr[\(PICAAttrName.boneWeight.rawValue)];\n"
        }
        
        str += "    float4 pos = animMatArr[boneIndex[0]] * float4(in.translation, 1.0) * boneWeight[0];\n"
        str += "    pos += animMatArr[boneIndex[1]] * float4(in.translation, 1.0) * boneWeight[1];\n"
        str += "    pos += animMatArr[boneIndex[2]] * float4(in.translation, 1.0) * boneWeight[2];\n"
        str += "    pos += animMatArr[boneIndex[3]] * float4(in.translation, 1.0) * boneWeight[3];\n"
        str += "    out.translation = projMat * mvMat * pos;\n"
        
        str += "    float3x3 matetialMat = float3x3(matetialMatArr[0], matetialMatArr[1], matetialMatArr[2]);\n"
        str += "    out.texcoord0.xy = (matetialMat * float3(texcoord0, 1.0)).xy;\n"
        str += "    out.texcoord1.xy = (matetialMat * float3(texcoord1, 1.0)).xy;\n"
        str += "    out.texcoord2.xy = (matetialMat * float3(texcoord2, 1.0)).xy;\n"
        str += "    return out;\n"
        str += "    }\n"
        
        
        str += "fragment half4 frag_func(\n"
        str += "        Vout in [[stage_in]],\n"
        str += "        sampler smp [[sampler(0)]],\n"
        str += "        texture2d<uint> diffuseTexture [[texture(0)]]) {\n"
        str += "    uint4 color = diffuseTexture.sample(smp, float2(in.texcoord0));\n"
        str += "    half4 ret = half4(color)/255.0;\n"
        str += "    return half4(ret);\n"
        str += "}\n"
        
        let library = try! RenderEngine.sharedInstance.device.makeLibrary(source: str, options: nil)
        let vertFunc = library.makeFunction(name: "vert_func")
        let fragFunc = library.makeFunction(name: "frag_func")
        return (vertFunc, fragFunc)
    }
}

