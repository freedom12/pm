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
    var rotation = Vector3.zero
    var translation = Vector3.zero
    
    var transform = Matrix4.identity
    
    var inheritTransform = Matrix4.identity
    var inverseTransform = Matrix4.identity
    
    init(gfBone:GFBone) {
        name = gfBone.name
        parentName = gfBone.parent
        
        scale = gfBone.scale
        rotation = gfBone.rotation
        translation = gfBone.position
        
        transform = Matrix4.init(scale: scale)
        transform = Matrix4.init(quaternion: Quaternion.init(pitch: rotation.x, yaw: 0, roll: 0)) * transform
        transform = Matrix4.init(quaternion: Quaternion.init(pitch: 0, yaw: rotation.y, roll: 0)) * transform
        transform = Matrix4.init(quaternion: Quaternion.init(pitch: 0, yaw: 0, roll: rotation.z)) * transform
        transform = Matrix4.init(translation: translation) * transform
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
