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
    var anims:[Anim] = []
    var baseBones:[Bone] = []
    var materialDict:Dictionary<String, Material> = [:]
    var textureDict:Dictionary<String, Texture> = [:]
    
    var curFrame = 0
    var animIndex = 0
    
    var transformBuffer:MTLBuffer? = nil
    
    init(gfModel:GFModelContainer){
        for gfMaterial in gfModel.materials {
            let material = Material.init(gfMaterial: gfMaterial)
            materialDict[material.name] = material
        }
        
        for gfMesh in gfModel.meshes {            
            let mesh = Mesh.init(gfMesh: gfMesh, to: self)
            meshes.append(mesh)
        }
        
        for gfBone in gfModel.bones {
            let bone = Bone.init(gfBone: gfBone)
            bone.parentIndex = findParentIndex(name: bone.parentName, in: gfModel.bones)
            baseBones.append(bone)
        }
        
        for bone in baseBones {
            bone.calTransform(bones: baseBones)
        }
    }
    
    private func findParentIndex(name:String, in Bones:[GFBone]) -> Int {
        for (index, gfBone) in baseBones.enumerated() {
            if gfBone.name == name {
                return index
            }
        }
        return -1
    }
    
    public func changeAnim(num:Int) {
        animIndex += num
        if animIndex >= anims.count {
            animIndex = 0
        }
        if animIndex < 0 {
            animIndex = anims.count - 1
        }
        curFrame = 0
    }
    
    public func updateFrame() {
        if anims.count == 0 {
            return
        }
        curFrame += 1
        if curFrame >= anims[animIndex].frameCount {
            curFrame = 0
        }
    }
    
    public func render(_ encoder:MTLRenderCommandEncoder) {
        let curBones = anims[animIndex].getSkeletonTransforms(at: curFrame)
        for mesh in meshes {
            let anim = anims[animIndex]
            if let visibility = anim.visibilityAnimDic[mesh.name] {
                if !visibility[curFrame] {
                    continue
                }
            }
            
            for subMesh in mesh.subMeshes {
                if subMesh.isVisible == false || subMesh.depthStencilState == nil {
                    continue
                }
                
                let material = materialDict[subMesh.materialName]!
                for (index, textureName) in material.textureNames.enumerated() {
                    let texture = textureDict[textureName]
                    encoder.setFragmentTexture(texture?.texture, index: index)
                    encoder.setFragmentSamplerState(material.samplerStates[index], index: index)
                    
                    if index == 0 {
                        var arr = material.transforms[0].toArray()
                        
                        if let transforms = anim.materialAnimDic[material.name + String(index)] {
                            let transform = transforms[curFrame]
                            let trans = Vector2.init(-transform.translation.x, -transform.translation.y)
                            var mat = Matrix3.init(translation: trans)
                            mat = Matrix3.init(rotation: transform.rotation) * mat
                            mat = Matrix3.init(scale: transform.scale) * mat
                            
                            arr = mat.toArray()
                        }
                        
                        encoder.setVertexBytes(arr, length: arr.count * MemoryLayout.size(ofValue: arr[0]), index: 3)
                    }
                }
                
                
                var transforms:[Matrix4] = Array.init(repeating: Matrix4.identity, count: 32)
                for i in 0 ..< transforms.count {
                    if i < subMesh.boneIndices.count && subMesh.boneIndices[i] < baseBones.count {
                        let boneIndex = subMesh.boneIndices[i]
                        var transform = curBones[boneIndex].inheritTransform
                        transform = transform * baseBones[boneIndex].inverseTransform
                        transforms[i] = transform
                    }
                }
                var transformArr:[Float] = []
                for i in transforms {
                    transformArr += i.toArray()
                }
                let len = transformArr.count * MemoryLayout.size(ofValue: transformArr[0])
                encoder.setVertexBytes(transformArr, length: len, index: 4)
                
                
                var fixedAttrArr:[Float] = []
                for i in subMesh.fixedAttrs {
                    fixedAttrArr += i.toArray()
                }
                encoder.setVertexBytes(fixedAttrArr, length: fixedAttrArr.count*MemoryLayout.size(ofValue: fixedAttrArr[0]), index: 10)
                
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
        
        if RenderEngine.sharedInstance.isRenderBone {
            var pointArr:[Float] = []
            for bone in curBones {
                if bone.parentIndex > 0 {
                    let arr2 = (Vector4.init(x: 0, y: 0, z: 0, w: 1)*curBones[bone.parentIndex].inheritTransform).toArray()
                    pointArr.append(arr2[0])
                    pointArr.append(arr2[1])
                    pointArr.append(arr2[2])
                    let arr1 = (Vector4.init(x: 0, y: 0, z: 0, w: 1)*bone.inheritTransform).toArray()
                    pointArr.append(arr1[0])
                    pointArr.append(arr1[1])
                    pointArr.append(arr1[2])
                }
            }
            
            let buffuer = RenderEngine.sharedInstance.device.makeBuffer(bytes: pointArr, length: pointArr.count * MemoryLayout.size(ofValue: pointArr[0]), options: [])
            let depthStencilDesc = MTLDepthStencilDescriptor.init()
            depthStencilDesc.depthCompareFunction = .always
            let depthStencilState = RenderEngine.sharedInstance.device.makeDepthStencilState(descriptor: depthStencilDesc)
            encoder.setDepthStencilState(depthStencilState)
            
            let vertDesc = MTLVertexDescriptor.init()
            vertDesc.attributes[0].format = .float3
            vertDesc.attributes[0].offset = 0
            vertDesc.attributes[0].bufferIndex = 0
            vertDesc.layouts[0].stride = 12
            vertDesc.layouts[0].stepRate = 1
            vertDesc.layouts[0].stepFunction = .perVertex
            
            let renderPiplineDesc = MTLRenderPipelineDescriptor.init()
            renderPiplineDesc.vertexFunction = RenderEngine.sharedInstance.defaultLibrary.makeFunction(name: "line_vertex")!
            renderPiplineDesc.fragmentFunction = RenderEngine.sharedInstance.defaultLibrary.makeFunction(name: "line_fragment")!
            renderPiplineDesc.vertexDescriptor = vertDesc
            renderPiplineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
            renderPiplineDesc.depthAttachmentPixelFormat = .depth32Float_stencil8
            renderPiplineDesc.stencilAttachmentPixelFormat = .depth32Float_stencil8
            let renderPipelineState = try! RenderEngine.sharedInstance.device.makeRenderPipelineState(descriptor: renderPiplineDesc)
            encoder.setRenderPipelineState(renderPipelineState)
            
            encoder.setVertexBuffer(buffuer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: pointArr.count/3)
        }
    }
}

