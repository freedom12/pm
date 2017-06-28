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
    var models:[Model] = []
    var projMat = Matrix4.identity
    var viewMat = Matrix4.identity
    
    var vertFunc:MTLFunction
    var fragFunc:MTLFunction
    
    override init() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        
        let defaultLibrary = device.makeDefaultLibrary()!
        vertFunc = defaultLibrary.makeFunction(name: "basic_vertex")!
        fragFunc = defaultLibrary.makeFunction(name: "basic_fragment")!
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
