//
//  GFSubMesh.swift
//  pm
//
//  Created by wanghuai on 2017/6/19.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class GFSubMesh {
    static let scales:[Float] = [
        1/Float(INT8_MAX),
        1/Float(UINT8_MAX),
        1/Float(INT16_MAX),
        1
    ]
    
    var file:FileHandle
    var hash = 0
    var name = ""
    var boneIndexCount = 0
    var boneIndices:[Int] = []
    
    var vertCount = 0
    var indexCount = 0
    var vertLength = 0
    var indexLength = 0
    
    var vertStride = 0
    var attrs:[PICAAttr] = []
    var fixedAttrs:[PICAFixedAttr] = []
    
    var indexFormate = false
    var primitivesCount = 0
    
    var rawBuffer:NSData = NSData.init()
    var indices:[Int] = []
    
    init( withFile _file:FileHandle, andDatasList datasList:[[Int]]) {
        file = _file
            
        hash = file.readUInt32()
        name = file.readString(len: file.readUInt32())
        
        boneIndexCount = file.readInt8()
        boneIndices = []
        for _ in 0 ..< 0x1f {
            boneIndices.append(file.readInt8())
        }
        
        vertCount = file.readUInt32()
        indexCount = file.readUInt32()
        vertLength = file.readUInt32()
        indexLength = file.readUInt32()
        
        let enableCmdReader = PICACommandReader.init(withDatas: datasList[0])
        var fixed:[[Int]] = Array.init(repeating: [0, 0, 0], count: 12)
        
        var bufferFormats:u_long = 0
        var bufferAttrs:u_long = 0
        var bufferPermutation:u_long = 0
        var attrCount = 0
        var attrTotal = 0
        
        var fixedIndex = 0
        
        for cmd in enableCmdReader.cmds {
            let param = cmd.params[0]
            
            switch cmd.register {
            case .GPUREG_ATTRIBBUFFERS_FORMAT_LOW: bufferFormats = bufferFormats | (u_long(param) << 0)
            case .GPUREG_ATTRIBBUFFERS_FORMAT_HIGH: bufferFormats = bufferFormats | (u_long(param) << 32)
            case .GPUREG_ATTRIBBUFFER0_CONFIG1: bufferAttrs = bufferAttrs | u_long(param)
            case .GPUREG_ATTRIBBUFFER0_CONFIG2:
                bufferAttrs = bufferAttrs | (u_long(param & 0xffff) << 32)
                vertStride = (param >> 16) & 0xff
                attrCount = param >> 28
            case .GPUREG_FIXEDATTRIB_INDEX: fixedIndex = param
            case .GPUREG_FIXEDATTRIB_DATA0: fixed[fixedIndex][0] = param
            case .GPUREG_FIXEDATTRIB_DATA1: fixed[fixedIndex][1] = param
            case .GPUREG_FIXEDATTRIB_DATA2: fixed[fixedIndex][2] = param
            case .GPUREG_VSH_NUM_ATTR: attrTotal = param+1
            case .GPUREG_VSH_ATTRIBUTES_PERMUTATION_LOW: bufferPermutation = bufferPermutation | (u_long(param) << 0)
            case .GPUREG_VSH_ATTRIBUTES_PERMUTATION_HIGH: bufferPermutation = bufferPermutation | (u_long(param) << 32)
            default: break
            }
        }
        
        for i in 0 ..< attrTotal {
            if ((bufferFormats >> (u_long(i) + 48)) & 1 == 0) {
                let permutationIndex = (bufferAttrs >> (u_long(i)*4)) & 0xf
                let attrName = bufferPermutation >> (permutationIndex*4) & 0xf
                let attrFormate = bufferFormats >> (permutationIndex*4) & 0xf
                
                var attr = PICAAttr.init()
                attr.name = PICAAttrName(rawValue: Int(attrName))!
                attr.formate = PICAAttrFormate(rawValue: Int(attrFormate & 3))!
                attr.elements = Int(attrFormate >> 2) + 1
                attr.scale = GFSubMesh.scales[Int(attrFormate & 3)]
                
                if (attr.name == .boneIndex) {
                    attr.scale = 1
                }
                attrs.append(attr)
            } else {
                let attrName = (bufferPermutation >> (u_long(i)*4)) & 0xf
                
                var fixedAttr = PICAFixedAttr.init()
                fixedAttr.name = PICAAttrName(rawValue: Int(attrName))!
                fixedAttr.value = Util.float24ToVect4(words: fixed[i])
                
                if (fixedAttr.name == .color || fixedAttr.name == .boneWeight) {
                    fixedAttr.value = fixedAttr.value * GFSubMesh.scales[1]
                }
                fixedAttrs.append(fixedAttr)
            }
        }
        
        let indexCmdReader = PICACommandReader.init(withDatas: datasList[2]) 
        for cmd in indexCmdReader.cmds {
            let param = cmd.params[0]
            
            switch cmd.register {
            case .GPUREG_INDEXBUFFER_CONFIG: indexFormate = ((param >> 31) != 0)
            case .GPUREG_NUMVERTICES: primitivesCount = param
            default: break
            }
        }
    }
    
    public func readVertBuffer() {
        rawBuffer = NSData.init(data: file.readData(ofLength: vertLength))
    }
    
    public func readIndexBuffer() {
        for _ in 0 ..< primitivesCount {
            if (indexFormate) {
                indices.append(file.readUInt16())
            } else {
                indices.append(file.readUInt8())
            }
        }
    }
}

