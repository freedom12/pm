//
//  GFMesh.swift
//  pm
//
//  Created by wanghuai on 2017/6/16.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFMesh {
    var file:FileHandle
    var hash = 0
    
    var BBoxMinVec:Vector4 = Vector4.init(0, 0, 0, 0)
    var BBoxMaxVec:Vector4 = Vector4.init(0, 0, 0, 0)
    var boneIndexPerVert = 0
    
    var subMeshes:[GFSubMesh] = []
    
    init( withFile _file:FileHandle ) {
        file = _file
        
        hash = file.readUInt32()
        name = file.readString(len: 0x40)
        
        _ = file.readUInt32()
        
        BBoxMinVec = file.readVector4()
        BBoxMaxVec = file.readVector4()
        
        let subMeshCount = file.readUInt32()
        boneIndexPerVert = file.readUInt32()
        
        file.seek(by: 0x10)
        
        var datasList:[[Int]] = []
        
        var cmdLength = 0
        var cmdIndex = 0
        var cmdCount = 0
        
        repeat {
            cmdLength = file.readUInt32()
            cmdIndex = file.readUInt32()
            cmdCount = file.readUInt32()
            _ = file.readUInt32()
            
            var datas:[Int] = []
            for _ in 0 ..< (cmdLength >> 2) {
                datas.append(file.readUInt32())
            }
            
            datasList.append(datas)
        } while (cmdIndex < cmdCount-1)
        
        for i in 0 ..< subMeshCount {
            let tmpDatasList = [datasList[i*3+0], datasList[i*3+1], datasList[i*3+2]]
            let subMesh = GFSubMesh.init(withFile: file, andDatasList: tmpDatasList)
            subMeshes.append(subMesh)
        }
    }
    
    var _name:String = ""
    var name:String {
        get {
            return _name
        }
        set {
            _name = newValue
        }
    }
}
