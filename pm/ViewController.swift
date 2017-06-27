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
    @IBOutlet weak var indexLabel: UILabel!
    
    
    @IBAction func lastHandler(_ sender: Any) {
        var i = index - 1
        if i < 1 {
            i = 10422/9
        }
        load(i)
    }
    
    @IBAction func nextHandler(_ sender: Any) {
        var i = index + 1
        if i > 10422/9 {
            i = 1
        }
        load(i)
    }
    
    
    var commandQueue: MTLCommandQueue! = nil
    
    var model:Model?
    var textures:[Texture] = []
    var textureDict:Dictionary<String, Texture> = [:]
    
    var mvMat:Matrix4 = Matrix4.identity
    var projMat:Matrix4 = Matrix4.identity
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mtkView.isMultipleTouchEnabled = true
        mtkView.delegate = self
        
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        
        commandQueue = mtkView.device?.makeCommandQueue()
        
        load(index)
        
        mvMat = Matrix4.init(translation: Vector3.init(0, -100, -400))
        projMat = Matrix4.init(fovx: 45*Float.pi/180, aspect: Scalar(mtkView.bounds.width/mtkView.bounds.height), near: 0.1, far: 10000)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView ) {
        //mega 宝石鬼，mega 海皇牙，火斑喵进化
        if index == 140 || index == 540 || index == 1037 {
            return
        }
        let commandBuffer = commandQueue!.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: mtkView.currentRenderPassDescriptor!)!
        if let meshes = model?.meshes {
            //        renderEncoder.setDepthBias(10000000, slopeScale: 1, clamp: 0)
            renderEncoder.setVertexBytes(projMat.toArray(), length: 16*4, index: 1)
            renderEncoder.setVertexBytes(mvMat.toArray(), length: 16*4, index: 2)
            for mesh in meshes {
                for subMesh in mesh.subMeshes {
                    var index = 0
                    for textureName in subMesh.material.textureNames {
                        let texture = textureDict[textureName]
                        renderEncoder.setFragmentTexture(texture?.texture, index: index)
                        renderEncoder.setFragmentSamplerState(subMesh.material.samplerStates[index], index: index)
                        index += 1
                    }
                    let arr = subMesh.material.transforms[0].toArray()
                    renderEncoder.setVertexBytes(arr, length: arr.count * MemoryLayout.size(ofValue: arr[0]), index: 3)
                    
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
        } else {
            
        }
        renderEncoder.endEncoding()
        
        commandBuffer.present(mtkView.currentDrawable!)
        commandBuffer.commit()
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 {
            for touch in touches {
                if touch.tapCount == 3 {
                    mvMat = Matrix4.init(translation: Vector3.init(0, -100, -400))
                    return
                }
                let p1 = touch.previousLocation(in: mtkView)
                let p2 = touch.location(in: mtkView)
                
                let vect1 = getArcBallVect(point: p1)
                let vect2 = getArcBallVect(point: p2)
                let vect = vect2-vect1
                let quaternion = Quaternion.init(pitch: 0, yaw: vect.x, roll: 0)
                mvMat = mvMat * Matrix4.init(quaternion: quaternion)
            }
        } else if touches.count == 2 {
            var touchList:[UITouch] = []
            for touch in touches {
                touchList.append(touch)
            }
            let p11 = touchList[0].previousLocation(in: mtkView)
            let p12 = touchList[0].location(in: mtkView)
            
            let p21 = touchList[1].previousLocation(in: mtkView)
            let p22 = touchList[1].location(in: mtkView)
            
            let p1 = CGPoint.init(x: (p21.x+p11.x)/2, y: (p21.y+p11.y)/2)
            let p2 = CGPoint.init(x: (p22.x+p12.x)/2, y: (p22.y+p12.y)/2)
            
            let vect = Vector3.init(Float(p2.x-p1.x), -Float(p2.y-p1.y), 0)
            mvMat = Matrix4.init(translation: vect) * mvMat
            
            let d1 = sqrt((p11.x - p21.x)*(p11.x - p21.x) + (p11.y - p21.y)*(p11.y - p21.y))
            let d2 = sqrt((p12.x - p22.x)*(p12.x - p22.x) + (p12.y - p22.y)*(p12.y - p22.y))
            let k = Float(d2/d1)
            mvMat = mvMat * Matrix4.init(scale: Vector3.init(k, k, k))
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
    
    var index = 1//1072
    func load(_ _index:Int) {
        index = _index
        let num = (index-1) * 9 + 1
        
        indexLabel.text = "No.\(num),\(index)"
        let package = GFPackage.init()
        
        
        let modelPath = Bundle.main.path(forResource: "res.bundle/file_\(String.init(format: "%05d", num))", ofType: "pc")!
        let modelFile = FileHandle.init(forReadingAtPath: modelPath)!
        package.merg(withFile: modelFile)
        modelFile.closeFile()
        
        let texturePath = Bundle.main.path(forResource: "res.bundle/file_\(String.init(format: "%05d", num+1))", ofType: "pc")!
        let textureFile = FileHandle.init(forReadingAtPath: texturePath)!
        package.merg(withFile: textureFile)
        textureFile.closeFile()
        
        if index == 1 {
            let animPath = Bundle.main.path(forResource: "res.bundle/file_\(String.init(format: "%05d", num+4))", ofType: "pc")!
            let animFile = FileHandle.init(forReadingAtPath: animPath)!
            package.merg(withFile: animFile)
            animFile.closeFile()
        }
        
        if let gfModel = package.model {
            model = Model.init(device: mtkView.device!, gfModel: gfModel)
            
            textures = []
            for gfTexture in package.textures {
                let texture = Texture.init(device: mtkView.device!, gfTexture: gfTexture)
                textures.append(texture)
                textureDict[gfTexture.name] = texture
            }
        }
    }
}

