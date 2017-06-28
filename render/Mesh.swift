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
    var name = ""
    var subMeshes:[SubMesh] = []
    unowned var parent:Model
    
    init(gfMesh:GFMesh, to model:Model){
        parent = model
        name = gfMesh.name
        for gfSubMesh in gfMesh.subMeshes {
            let subMesh = SubMesh.init(gfSubMesh: gfSubMesh, to: self)
            subMeshes.append(subMesh)
        }
    }
}
