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
    var device:MTLDevice! = nil
    init(device _device:MTLDevice, gfModel:GFModelContainer){
        device = _device
        for gfMaterial in gfModel.materials {
            let material = Material.init(device: device, gfMaterial: gfMaterial)
            materialDict[material.name] = material
        }
        
        for gfMesh in gfModel.meshes {            
            let mesh = Mesh.init(device: device, gfMesh: gfMesh, to: self)
            meshes.append(mesh)
        }
    }
}

