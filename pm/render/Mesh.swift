//
//  Mesh.swift
//  pm
//
//  Created by wanghuai on 2017/6/20.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
import Metal

class Mesh {
    var subMeshes:[SubMesh] = []
    var parent:Model! = nil
    
    var device:MTLDevice! = nil
    init(device _device:MTLDevice, gfMesh:GFMesh, to model:Model){
        device = _device
        parent = model
        
        for gfSubMesh in gfMesh.subMeshes {
            let subMesh = SubMesh.init(device: device, gfSubMesh: gfSubMesh, to: self)
            subMeshes.append(subMesh)
        }
    }
}
