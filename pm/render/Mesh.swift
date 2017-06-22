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
    var material:Material! = nil
    
    var device:MTLDevice! = nil
    init(device _device:MTLDevice, gfMesh:GFMesh, material _material:Material){
        device = _device
        material = _material
        
        for gfSubMesh in gfMesh.subMeshes {
            let subMesh = SubMesh.init(device: device, gfSubMesh: gfSubMesh, material: material)
            subMeshes.append(subMesh)
        }
    }
}
