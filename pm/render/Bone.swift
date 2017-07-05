//
//  Bone.swift
//  pm_ios
//
//  Created by wanghuai on 2017/6/28.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class Bone {
    var name = ""
    var parentName = ""
    var parentIndex = -1
    var scale = Vector3.zero
    var rotation = Quaternion.identity
    var translation = Vector3.zero
    
    var rotation2 = Vector3.zero
//    var transform = Matrix4.identity
    
    var inheritTransform = Matrix4.identity
    var inverseTransform = Matrix4.identity
    
    init(gfBone:GFBone) {
        name = gfBone.name
        parentName = gfBone.parent
        
        scale = gfBone.scale
        rotation = Quaternion.init(axisAngle: Vector4.init(Vector3.z, w: gfBone.rotation.z)) *
            Quaternion.init(axisAngle: Vector4.init(Vector3.y, w: gfBone.rotation.y)) *
            Quaternion.init(axisAngle: Vector4.init(Vector3.x, w: gfBone.rotation.x))
        translation = gfBone.position
        
        rotation2 = gfBone.rotation
    }
    
    init(bone:Bone) {
        name = bone.name
        parentName = bone.parentName
        parentIndex = bone.parentIndex
        
        scale = bone.scale
        rotation = bone.rotation
        translation = bone.translation
    }
    
    var transform:Matrix4 {
        get {
            var ret = Matrix4.init(scale: scale)
//            ret = Matrix4.init(quaternion: Quaternion.init(pitch: rotation.x, yaw: 0, roll: 0)) * ret
//            ret = Matrix4.init(quaternion: Quaternion.init(pitch: 0, yaw: rotation.y, roll: 0)) * ret
//            ret = Matrix4.init(quaternion: Quaternion.init(pitch: 0, yaw: 0, roll: rotation.z)) * ret
//            ret = Matrix4.init(quaternion: Quaternion.init(axisAngle: Vector4.init(Vector3.z, w: rotation.z)) * Quaternion.init(axisAngle: Vector4.init(Vector3.y, w: rotation.y)) * Quaternion.init(axisAngle: Vector4.init(Vector3.x, w: rotation.x)))
            ret = Matrix4.init(quaternion: rotation) * ret
            ret = Matrix4.init(translation: translation) * ret
            return ret
        }
    }
    
    public func calTransform(bones:[Bone]) {
        var transform = Matrix4.identity
        var bone = self
        
        while true {
            transform = bone.transform * transform
            if bone.parentIndex == -1 {
                break
            }
            bone = bones[bone.parentIndex]
        }
        
        inheritTransform = transform
        inverseTransform = transform.inverse
    }
}
