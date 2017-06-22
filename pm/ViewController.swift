//
//  ViewController.swift
//  pm
//
//  Created by wanghuai on 2017/6/14.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import UIKit
import Metal
import QuartzCore
import MetalKit

class ViewController: UIViewController, MTKViewDelegate {
    
    @IBOutlet weak var mtkView: MTKView!
    
    
    var commandQueue: MTLCommandQueue! = nil
    
    var model:Model! = nil
    var textures:[Texture] = []
    var textureDict:Dictionary<String, Texture> = [:]
    
    var mvMatBuffer:MTLBuffer! = nil
    var projMatBuffer:MTLBuffer! = nil
    var mvMat:Matrix4 = Matrix4.identity
    var projMat:Matrix4 = Matrix4.identity
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mtkView.isMultipleTouchEnabled = true
        mtkView.delegate = self
        
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        
        commandQueue = mtkView.device?.makeCommandQueue()
        
        load()
        
        setMVMatBuffer(mat: Matrix4.init(translation: Vector3.init(0, 0, -100)))
        setProjMatBuffer(mat: Matrix4.init(fovx: 60*Float.pi/180, aspect: Float(mtkView.bounds.width/mtkView.bounds.height), near: 0.001, far: 1000))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView ) {
        let commandBuffer = commandQueue!.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: mtkView.currentRenderPassDescriptor!)!
        renderEncoder.setVertexBuffer(projMatBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(mvMatBuffer, offset: 0, index: 2)
        for mesh in model.meshes {
            let material = mesh.material!
            var index = 0
            for textureName in material.textureNames {
                let texture = textureDict[textureName]
                renderEncoder.setFragmentTexture(texture?.texture, index: index)
                renderEncoder.setFragmentSamplerState(material.samplerStates[index], index: index)
                index += 1
            }
            
            for subMesh in mesh.subMeshes {
                renderEncoder.setCullMode(subMesh.material.cullMode)
                renderEncoder.setStencilReferenceValue(subMesh.material.stencilReference)
                renderEncoder.setDepthStencilState(subMesh.depthStencilState)
                renderEncoder.setRenderPipelineState(subMesh.renderPipelineState)
                renderEncoder.setVertexBuffer(subMesh.vertBuffer, offset: 0, index: 0)
                renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                    indexCount: subMesh.indexCount,
                                                    indexType: subMesh.indexType,
                                                    indexBuffer: subMesh.indexBuffer,
                                                    indexBufferOffset: 0)
            }
        }
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(mtkView.currentDrawable!)
        commandBuffer.commit()
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 {
            for touch in touches {
                if touch.tapCount == 2 {
                    setMVMatBuffer(mat: Matrix4.init(translation: Vector3.init(0, 0, -100)))
                    return
                }
                let p1 = touch.previousLocation(in: mtkView)
                let p2 = touch.location(in: mtkView)
                
                let vect1 = getArcBallVect(point: p1)
                let vect2 = getArcBallVect(point: p2)
                
                let quaternion = Quaternion.init(pitch: vect2.y-vect1.y, yaw: vect2.x-vect1.x, roll: vect2.z-vect1.z)
                let mat = Matrix4.init(quaternion: quaternion)
                setMVMatBuffer(mat: mvMat * mat)
            }
        } else if touches.count == 2 {
            var touchList:[UITouch] = []
            for touch in touches {
                touchList.append(touch)
            }
            let p11 = touchList[0].previousLocation(in: mtkView)
            let p12 = touchList[0].location(in: mtkView)
            let p1 = CGPoint.init(x: (p12.x+p11.x)/2, y: (p12.y+p11.y)/2)
            let p21 = touchList[1].previousLocation(in: mtkView)
            let p22 = touchList[1].location(in: mtkView)
            let p2 = CGPoint.init(x: (p22.x+p21.x)/2, y: (p22.y+p21.y)/2)
            
            let vect = Vector3.init(Float(p2.y-p1.y), Float(p2.x-p1.x), 0)/500
            let mat = Matrix4.init(translation: vect)
            setMVMatBuffer(mat: mat * mvMat)
        }
    }
    
    private func getArcBallVect(point:CGPoint) -> Vector3 {
        var vect = Vector3.init(1, 1, 1)
        vect.x = (Float(point.x) / Float(mtkView.bounds.width)) * 2.0 - 1.0
        vect.y = (Float(point.y) / Float(mtkView.bounds.height)) * 2.0 - 1.0
        let d = vect.x * vect.x + vect.y * vect.y
        if d < 1 {
            vect.z = sqrt(1 - d)
        } else {
            let len = sqrt(d)
            vect.x /= len
            vect.y /= len
            vect.z = 0
        }
        
        return vect
    }
    
    private func setMVMatBuffer(mat:Matrix4) {
        mvMat = mat
        let arr = mvMat.toArray()
        let len = arr.count*MemoryLayout.size(ofValue: arr[0])
        mvMatBuffer = mtkView.device?.makeBuffer(bytes: arr, length: len, options: [])
    }
    
    private func setProjMatBuffer(mat:Matrix4) {
        projMat = mat
        let arr = projMat.toArray()
        let len = arr.count*MemoryLayout.size(ofValue: arr[0])
        projMatBuffer = mtkView.device?.makeBuffer(bytes: arr, length: len, options: [])
    }
    
    func load() {
        let package = GFPackage.init()
        
        let modelPath = Bundle.main.path(forResource: "res.bundle/file_00001", ofType: "pc")!
        let modelFile = FileHandle.init(forReadingAtPath: modelPath)!
        package.merg(withFile: modelFile)
        modelFile.closeFile()
        
        let texturePath = Bundle.main.path(forResource: "res.bundle/file_00002", ofType: "pc")!
        let textureFile = FileHandle.init(forReadingAtPath: texturePath)!
        package.merg(withFile: textureFile)
        textureFile.closeFile()
        
        
        let gfModel = package.model!
        model = Model.init(device: mtkView.device!, gfModel: gfModel)
        
        textures = []
        for gfTexture in package.textures {
            let texture = Texture.init(device: mtkView.device!, gfTexture: gfTexture)
            textures.append(texture)
            textureDict[gfTexture.name] = texture
        }
    }
}

