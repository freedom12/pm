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

class ViewController: UIViewController {
    
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
    
    @IBAction func nextAnimHandler(_ sender: Any) {
        model?.changeAnim(num: 1)
    }
    @IBAction func lastAnimHandler(_ sender: Any) {
        model?.changeAnim(num: -1)
    }
    
    @IBAction func changeBoneHandler(_ sender: Any) {
        RenderEngine.sharedInstance.isRenderBone = !RenderEngine.sharedInstance.isRenderBone
    }
    
    var viewMat:Matrix4 = Matrix4.identity
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView.delegate = RenderEngine.sharedInstance
        mtkView.device = RenderEngine.sharedInstance.device
        mtkView.clearColor = MTLClearColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        
        viewMat = Matrix4.init(translation: Vector3.init(0, -100, -400))
        RenderEngine.sharedInstance.viewMat = viewMat
        RenderEngine.sharedInstance.projMat = Matrix4.init(fovx: 45*Float.pi/180,
                                            aspect: Scalar(mtkView.bounds.width/mtkView.bounds.height),
                                            near: 0.1, far: 10000)
        
        index = (UserDefaults.standard.value(forKey: "pmIndex") as? Int) ?? 1
//        index = 1
        load(index)
    }
    
    var index = 1
    var model:Model? = nil
    var timer:Timer! = nil
    private func load(_ _index:Int) {
        index = _index
        let num = (index-1) * 9 + 1
        
        indexLabel.text = "No.\(num),\(index)"
        UserDefaults.standard.set(index, forKey: "pmIndex")
        UserDefaults.standard.synchronize()
        
        model = FileLoader.sharedInstance.load(gfPackageIndex: index)
        RenderEngine.sharedInstance.clear()
        RenderEngine.sharedInstance.add(model: model)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
            self.model?.updateFrame()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 {
            for touch in touches {
                if touch.tapCount == 3 {
                    viewMat = Matrix4.init(translation: Vector3.init(0, -100, -400))
                    RenderEngine.sharedInstance.viewMat = viewMat
                    return
                }
                let p1 = touch.previousLocation(in: mtkView)
                let p2 = touch.location(in: mtkView)
                
                let vect1 = getArcBallVect(point: p1)
                let vect2 = getArcBallVect(point: p2)
                let vect = vect2-vect1
                let quaternion = Quaternion.init(pitch: 0, yaw: vect.x, roll: 0)
                viewMat = viewMat * Matrix4.init(quaternion: quaternion)
                RenderEngine.sharedInstance.viewMat = viewMat
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
            viewMat = Matrix4.init(translation: vect) * viewMat
            
            let d1 = sqrt((p11.x - p21.x)*(p11.x - p21.x) + (p11.y - p21.y)*(p11.y - p21.y))
            let d2 = sqrt((p12.x - p22.x)*(p12.x - p22.x) + (p12.y - p22.y)*(p12.y - p22.y))
            let k = Float(d2/d1)
            viewMat = viewMat * Matrix4.init(scale: Vector3.init(k, k, k))
            RenderEngine.sharedInstance.viewMat = viewMat
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
}

