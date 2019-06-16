//
//  RenderEngine.swift
//  pm_ios
//
//  Created by wanghuai on 2017/6/28.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
import MetalKit

class RenderEngine:NSObject, MTKViewDelegate {
    static let sharedInstance = RenderEngine()
    
    var device:MTLDevice! = nil
    var commandQueue: MTLCommandQueue! = nil
    var defaultLibrary:MTLLibrary! = nil
    var models:[Model] = []
    var projMat = Matrix4.identity
    var viewMat = Matrix4.identity
    
    var vertFunc:MTLFunction
    var fragFunc:MTLFunction
    
    var vertFunc_t0_bi_bw:MTLFunction
    var vertFunc_t0_bi:MTLFunction
    var vertFunc_t0_bw:MTLFunction
    var vertFunc_t0:MTLFunction
    var fragFunc_t0:MTLFunction
    
    var isRenderBone = true
    
    override init() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        
        defaultLibrary = device.makeDefaultLibrary()!
        vertFunc = defaultLibrary.makeFunction(name: "basic_vertex")!
        fragFunc = defaultLibrary.makeFunction(name: "basic_fragment")!
        
        vertFunc_t0_bi_bw = defaultLibrary.makeFunction(name: "vertex_t0_bi_bw")!
        vertFunc_t0_bi = defaultLibrary.makeFunction(name: "vertex_t0_bi")!
        vertFunc_t0_bw = defaultLibrary.makeFunction(name: "vertex_t0_bw")!
        vertFunc_t0 = defaultLibrary.makeFunction(name: "vertex_t0")!
        fragFunc_t0 = defaultLibrary.makeFunction(name: "fragment_t0")!
    }
    
    public func clear() {
        models = []
    }
    
    public func add(model:Model?) {
        if let model = model {
            models.append(model)
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView ) {
        let commandBuffer = commandQueue!.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!)!
        
        renderEncoder.setVertexBytes(projMat.toArray(), length: 16*4, index: 1)
        renderEncoder.setVertexBytes(viewMat.toArray(), length: 16*4, index: 2)
        for model in models {
            model.render(renderEncoder)
        }
        renderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
