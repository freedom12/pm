//
//  ViewController.swift
//  pm_mac
//
//  Created by wanghuai on 2017/6/27.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
    
    var mtkView:MTKView! = nil
    var viewMat:Matrix4 = Matrix4.identity
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView = MTKView()
        mtkView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        mtkView.delegate = RenderEngine.sharedInstance
        mtkView.device = RenderEngine.sharedInstance.device
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        mtkView.clearDepth = 1
        mtkView.clearStencil = 0
        self.view.addSubview(mtkView)
        
        viewMat = Matrix4.init(translation: Vector3.init(0, -50, -400))
        RenderEngine.sharedInstance.viewMat = viewMat
        RenderEngine.sharedInstance.projMat = Matrix4.init(fovx: 45*Float.pi/180,
                                                           aspect: Scalar(mtkView.bounds.width/mtkView.bounds.height),
                                                           near: 0.1, far: 10000)
        
        load(index)
    }
    
    var index = 1//1072
    func load(_ _index:Int) {
        index = _index
        
        //mega 宝石鬼，mega 海皇牙，火斑喵进化
        if index == 140 || index == 540 || index == 1037 {
            return
        }
        
        let model = FileLoader.sharedInstance.load(gfPackageIndex: index)
        RenderEngine.sharedInstance.clear()
        RenderEngine.sharedInstance.add(model: model)
    }
}

