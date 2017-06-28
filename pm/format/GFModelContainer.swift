//
//  GFModelContainer.swift
//  pm
//
//  Created by wanghuai on 2017/6/14.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

struct Section {
    var magic = ""
    var len = 0
    var addr = 0
    var padding = 0
}

struct HashName {
    var hash = 0
    var name = ""
    
    init() {
        hash = 0
        name = ""
    }
    init( withFile file:FileHandle) {
        hash = file.readUInt32()
        name = file.readStringByte()
    }
}

struct Color {
    var r = 0
    var g = 0
    var b = 0
    var a = 0
    
    init() {
        r = 0
        g = 0
        b = 0
        a = 0
    }
    
    init( withInt int:Int) {
        r = (int >> 0) & 0xff
        g = (int >> 8) & 0xff
        b = (int >> 16) & 0xff
        a = (int >> 24) & 0xff
    }
    
    init( withFile file:FileHandle) {
        r = file.readUInt8()
        g = file.readUInt8()
        b = file.readUInt8()
        a = file.readUInt8()
    }
}

class GFModelContainer:GFContainer {
    var sections:[Section] = []
    var shaderNames:[HashName] = []
    var lutNames:[HashName] = []
    var materialNames:[HashName] = []
    var meshNames:[HashName] = []
    
    var bones:[GFBone] = []
    var luts:[GFLut] = []
    var materials:[GFMaterial] = []
    var meshes:[GFMesh] = []
    
    var BBoxMinVec:Vector4 = Vector4.init(0, 0, 0, 0)
    var BBoxMaxVec:Vector4 = Vector4.init(0, 0, 0, 0)
    var transform:Matrix4 = Matrix4.init(scale: Vector3.init(1, 1, 1))
    
    override init( withFile _file:FileHandle ) {
        super.init(withFile: _file)
        
        let sectionCount = file.readUInt32()
        file.skipPadding()
        sections = []
        for _ in 0 ..< sectionCount {
            var section = Section()
            section.magic = file.readString(len: 8)
            section.len = file.readUInt32()
            section.padding = file.readUInt32()
            section.addr = file.pos
            sections.append(section)
            file.seek(by: section.len)
        }
        
        for section in sections {
            file.seek(to: section.addr)
            switch section.magic {
            case "gfmodel": readModel()
            case "material": readMaterial()
            case "mesh": readMesh()
            default: break
            }
        }
    }
    
    private func readModel() {
        shaderNames = getHashNames()
        lutNames = getHashNames()
        materialNames = getHashNames()
        meshNames = getHashNames()
        
        BBoxMinVec = file.readVector4()
        BBoxMaxVec = file.readVector4()
        transform = file.readMatrix4()
        
        let unknownDataLen = file.readUInt32()
        let unknownDataOffset = file.readUInt32()
        let _ = file.readUInt64()
        
        file.seek(by: unknownDataLen+unknownDataOffset)
        
        let boneCount = file.readUInt32()
        file.seek(by: 0xc)
        bones = []
        for _ in 0 ..< boneCount {
            let bone = GFBone.init(withFile: file)
            bones.append(bone)
        }
        file.skipPadding()
        
        let lutCount = file.readUInt32()
        let lutLen = file.readUInt32()
        file.skipPadding()
        luts = []
        for i in 0 ..< lutCount {
            let lut = GFLut.init(withFile: file, andLen: lutLen)
            lut.name = "smaple_" + String(i)
            luts.append(lut)
        }
    }
    
    private func readMaterial() {
        let meterial = GFMaterial.init(withFile: file)
        meterial.name = materialNames[materials.count].name
        materials.append(meterial)
        
    }
    
    private func readMesh() {
        let mesh = GFMesh.init(withFile: file)
        mesh.name = meshNames[meshes.count].name
        meshes.append(mesh)
    }
    
    private func getHashNames() -> [HashName] {
        let hashNameCount = file.readUInt32()
        var hashNames:[HashName] = []
        if hashNameCount == 0 {
            return hashNames
        }
        for _ in 0...(hashNameCount-1) {
            var hashName = HashName()
            hashName.hash = file.readUInt32()
            hashName.name = file.readString(len: 0x40)
            hashNames.append(hashName)
        }
        return hashNames
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
