//
//  GFTexture.swift
//  pm
//
//  Created by wanghuai on 2017/6/16.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFSampler {
    var file:FileHandle
    
    var hash = 0
    var name = ""
    
    var mappingType:GFTextureMappingType = .UVCoordinateMap
    var scale = Vector2.init(0, 0)
    var rotation:Float = 0
    var position = Vector2.init(0, 0)
    
    var wrapU:GFTextureWrap = .clampToEdge
    var wrapV:GFTextureWrap = .clampToEdge
    
    var MaxFilter:GFTextureMaxFilter = .nearest
    var MinFilter:GFTextureMinFilter = .nearest
    
    var minLOD = 0
    
    init( withFile _file:FileHandle ) {
        file = _file
        
        hash = file.readUInt32()
        name = file.readStringByte()
        
        _ = file.readUInt8()
        mappingType = GFTextureMappingType.init(rawValue: file.readUInt8())!
        
        scale = file.readVector2()
        rotation = file.readSingle()
        position = file.readVector2()
      
        wrapU = GFTextureWrap.init(rawValue: file.readUInt32())!
        wrapV = GFTextureWrap.init(rawValue: file.readUInt32())!
        
        MaxFilter = GFTextureMaxFilter.init(rawValue: file.readUInt32())!
        MinFilter = GFTextureMinFilter.init(rawValue: file.readUInt32())!
        
        minLOD = file.readUInt32()
    }
}

enum GFTextureMappingType:Int {
    case UVCoordinateMap = 0
    case cameraCubEnvMap
    case cameraSphereEnvMap
    case ProjectionMap
    case shadow
    case shadowBox
}

enum GFTextureWrap:Int {
    case clampToEdge = 0
    case clampToBorder
    case `repeat`
    case mirror
}

enum GFTextureMaxFilter:Int {
    case nearest = 0
    case linear
}

enum GFTextureMinFilter:Int {
    case nearest = 0
    case nearestMinmapNearest
    case nearestMinmapLinear
    case linear
    case linearMinmapNearest
    case linearMinmapLinear
}


