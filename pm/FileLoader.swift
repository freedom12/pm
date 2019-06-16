//
//  FileLoader.swift
//  pm_ios
//
//  Created by wanghuai on 2017/6/28.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation

class FileLoader {
    static let sharedInstance = FileLoader()
    
    public func load(gfPackageIndex index:Int) -> Model? {
        let num = (index-1) * 9 + 1
        let package = GFPackage.init()
        
        var startTime:CFAbsoluteTime
        var endTime:CFAbsoluteTime

        
        
        startTime = CFAbsoluteTimeGetCurrent()
        if let modelPath = Bundle.main.path(forResource: "res.bundle/pc/file_\(String.init(format: "%05d", num))", ofType: "pc") {
            if let modelFile = FileHandle.init(forReadingAtPath: modelPath) {
                package.merg(withFile: modelFile)
                modelFile.closeFile()
            }
        }
        endTime = CFAbsoluteTimeGetCurrent()
        debugPrint("代码执行时长：%f 毫秒", (endTime - startTime)*1000)
        
        startTime = CFAbsoluteTimeGetCurrent()
        if let texturePath = Bundle.main.path(forResource: "res.bundle/pc/file_\(String.init(format: "%05d", num+1))", ofType: "pc") {
            if let textureFile = FileHandle.init(forReadingAtPath: texturePath) {
                package.merg(withFile: textureFile)
                textureFile.closeFile()
            }
        }
        endTime = CFAbsoluteTimeGetCurrent()
        debugPrint("代码执行时长：%f 毫秒", (endTime - startTime)*1000)
        
        startTime = CFAbsoluteTimeGetCurrent()
        if let animPath = Bundle.main.path(forResource: "res.bundle/pc/file_\(String.init(format: "%05d", num+4))", ofType: "pc") {
            if let animFile = FileHandle.init(forReadingAtPath: animPath) {
                package.merg(withFile: animFile)
                animFile.closeFile()
            }
        }
        endTime = CFAbsoluteTimeGetCurrent()
        debugPrint("代码执行时长：%f 毫秒", (endTime - startTime)*1000)
//        if let animPath = Bundle.main.path(forResource: "res.bundle/pc/file_\(String.init(format: "%05d", num+5))", ofType: "pc") {
//            if let animFile = FileHandle.init(forReadingAtPath: animPath) {
//                package.merg(withFile: animFile)
//                animFile.closeFile()
//            }
//        }
//
//        if let animPath = Bundle.main.path(forResource: "res.bundle/pc/file_\(String.init(format: "%05d", num+6))", ofType: "pc") {
//            if let animFile = FileHandle.init(forReadingAtPath: animPath) {
//                package.merg(withFile: animFile)
//                animFile.closeFile()
//            }
//        }
        
        if let gfModel = package.model {
            startTime = CFAbsoluteTimeGetCurrent()
            let model = Model.init(gfModel: gfModel)
            endTime = CFAbsoluteTimeGetCurrent()
            debugPrint("代码执行时长：%f 毫秒", (endTime - startTime)*1000)
            
            startTime = CFAbsoluteTimeGetCurrent()
            for gfTexture in package.textures {
                let texture = Texture.init(gfTexture: gfTexture)
                model.textureDict[gfTexture.name] = texture
            }
            endTime = CFAbsoluteTimeGetCurrent()
            debugPrint("代码执行时长：%f 毫秒", (endTime - startTime)*1000)
            
            startTime = CFAbsoluteTimeGetCurrent()
            for gfAnim in package.anims {
                let anim = Anim.init(gfAnim: gfAnim, bones: model.baseBones, materials: model.materialDict)
                model.anims.append(anim)
            }
            endTime = CFAbsoluteTimeGetCurrent()
            debugPrint("代码执行时长：%f 毫秒", (endTime - startTime)*1000)
            return model
        }
        return nil
    }
}
