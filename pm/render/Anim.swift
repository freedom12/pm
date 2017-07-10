//
//  Anim.swift
//  pm
//
//  Created by wanghuai on 2017/6/28.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class Anim {
    var skeletonElements:[AnimElement] = []
    var visibilityAnim:GFVisibilityAnim? = nil
    
    var bones:[Bone] = []
    
    var frameCount = 0
    var isLoop = false
    init(gfAnim:GFAnim, bones _bones:[Bone]) {
        frameCount = gfAnim.frameCount
        isLoop = gfAnim.isLoop
        bones = _bones
        if let skeletonAnim = gfAnim.skeletonAnim {
            for transform in skeletonAnim.transforms {
                let bone = findBone(name: transform.name, in: bones)
                if let bone = bone {
                    var animElement = AnimElement()
                    animElement.name = transform.name
                    animElement.primitiveType = .quatTransform
                    for frame in 0 ..< frameCount {
                        var scale = bone.scale
                        scale.x = getValue(at: frame, from: transform.scaleXFrames, value: scale.x)
                        scale.y = getValue(at: frame, from: transform.scaleYFrames, value: scale.y)
                        scale.z = getValue(at: frame, from: transform.scaleZFrames, value: scale.z)
                        
                        var rotation = bone.rotation2
                        rotation.x = getValue(at: frame, from: transform.rotationXFrames, value: rotation.x)
                        rotation.y = getValue(at: frame, from: transform.rotationYFrames, value: rotation.y)
                        rotation.z = getValue(at: frame, from: transform.rotationZFrames, value: rotation.z)
                        
                        var translation = bone.translation
                        translation.x = getValue(at: frame, from: transform.translationXFrames, value: translation.x)
                        translation.y = getValue(at: frame, from: transform.translationYFrames, value: translation.y)
                        translation.z = getValue(at: frame, from: transform.translationZFrames, value: translation.z)
                        
                        var quat = Quaternion.identity
                        if transform.isAxisAngle {
                            quat = Quaternion.init(axisAngle: Vector4.init(rotation.normalized(), w: rotation.length * 2))
                        } else {
                            quat = Quaternion.init(axisAngle: Vector4.init(Vector3.z, w: rotation.z)) * Quaternion.init(axisAngle: Vector4.init(Vector3.y, w: rotation.y)) * Quaternion.init(axisAngle: Vector4.init(Vector3.x, w: rotation.x))
                        }
                        
                        let transform = Transform(scale: scale, rotation: quat, translation: translation)
                        animElement.transforms.append(transform)
                    }
                    skeletonElements.append(animElement)
                }
            }
        }
        
        visibilityAnim = gfAnim.visibilityAnim
    }
    
    private func findBone(name:String, in bones:[Bone]) -> Bone? {
        for bone in bones {
            if bone.name == name {
                return bone
            }
        }
        return nil
    }
    
    private func getValue(at frame:Int, from keyFrames:[GFKeyFrame], value:Float) -> Float {
        if keyFrames.count <= 0 {
            return value
        }
        if keyFrames.count == 1 {
            return keyFrames[0].value
        }
        var lhs:GFKeyFrame = keyFrames[0]
        for (index, keyFrame) in keyFrames.enumerated() {
            if keyFrame.frame <= frame {
                lhs = keyFrames[index]
            }
        }
        var rhs:GFKeyFrame = keyFrames[keyFrames.count - 1]
        for (index, keyFrame) in keyFrames.enumerated() {
            if keyFrame.frame >= frame {
                rhs = keyFrames[index]
                break
            }
        }
        
        if lhs.frame == rhs.frame {
            return lhs.value
        }
        
        let diff = Float(frame - lhs.frame)
        let weight = diff / Float(rhs.frame - lhs.frame)
        var result = lhs.value
        result += (lhs.value - rhs.value) * (2 * weight - 3) * weight * weight
        result += (diff * (weight - 1)) * (lhs.slope * (weight - 1) + rhs.slope * weight)
        return result
    }
    
    public func getTransforms(at frame:Int) -> [Bone] {
        //todo 缩放继承的骨骼动画可能会有问题？
        var tmpBones:[Bone] = []
        for bone in bones {
            let tmpBone = Bone.init(bone: bone)
            let arr = skeletonElements.filter({$0.name == bone.name})
            if arr.count > 0 {
                let elem = arr[0]
                switch elem.primitiveType {
                case .quatTransform:
                    tmpBone.scale = elem.transforms[frame].scale
                    tmpBone.rotation = elem.transforms[frame].rotation
                    tmpBone.translation = elem.transforms[frame].translation
                default: break
                }
            }
            tmpBones.append(tmpBone)
        }
        
        for bone in tmpBones {
            bone.calTransform(bones: tmpBones)
        }
        return tmpBones
    }
}

struct Transform {
    var scale = Vector3.init(0, 0, 0)
    var rotation = Quaternion.identity
    var translation = Vector3.init(0, 0, 0)
}

struct AnimElement {
    var name = ""
    var transforms:[Transform] = []
    var targetType = 1
    var primitiveType:AnimPrimitiveType = .float
}

enum AnimPrimitiveType:Int {
    case float = 0
    case integer
    case vect2d
    case vect3d
    case transform
    case rgba
    case texture
    case quatTransform
    case boolean
    case mtxTransform
}
