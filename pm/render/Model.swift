//
//  Model.swift
//  pm
//
//  Created by wanghuai on 2017/6/19.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
import Metal

class Model {
    var meshes:[Mesh] = []
    var materialDict:Dictionary<String, Material> = [:]
    var textureDict:Dictionary<String, Texture> = [:]
    
    init(gfModel:GFModelContainer){
        for gfMaterial in gfModel.materials {
            let material = Material.init(gfMaterial: gfMaterial)
            materialDict[material.name] = material
        }
        
        for gfMesh in gfModel.meshes {            
            let mesh = Mesh.init(gfMesh: gfMesh, to: self)
            meshes.append(mesh)
        }
    }
    
    public func render(_ encoder:MTLRenderCommandEncoder) {
        for mesh in meshes {
            for subMesh in mesh.subMeshes {
                let material = materialDict[subMesh.materialName]!
                for (index, textureName) in material.textureNames.enumerated() {
                    let texture = textureDict[textureName]
                    encoder.setFragmentTexture(texture?.texture, index: index)
                    encoder.setFragmentSamplerState(material.samplerStates[index], index: index)
                }
                let arr = material.transforms[0].toArray()
                encoder.setVertexBytes(arr, length: arr.count * MemoryLayout.size(ofValue: arr[0]), index: 3)
                
                encoder.setCullMode(material.cullMode)
                encoder.setStencilReferenceValue(material.stencilReference)
                encoder.setDepthStencilState(subMesh.depthStencilState)
                encoder.setRenderPipelineState(subMesh.renderPipelineState)
                encoder.setVertexBuffer(subMesh.vertBuffer, offset: 0, index: 0)
                encoder.drawIndexedPrimitives(type: .triangle,
                                                    indexCount: subMesh.indexCount,
                                                    indexType: subMesh.indexType,
                                                    indexBuffer: subMesh.indexBuffer,
                                                    indexBufferOffset: 0)
            }
        }
    }
}

