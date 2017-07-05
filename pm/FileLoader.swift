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
        
        if let modelPath = Bundle.main.path(forResource: "res.bundle/file_\(String.init(format: "%05d", num))", ofType: "pc") {
            if let modelFile = FileHandle.init(forReadingAtPath: modelPath) {
                package.merg(withFile: modelFile)
                modelFile.closeFile()
            }
        }
        
        
        if let texturePath = Bundle.main.path(forResource: "res.bundle/file_\(String.init(format: "%05d", num+1))", ofType: "pc") {
            if let textureFile = FileHandle.init(forReadingAtPath: texturePath) {
                package.merg(withFile: textureFile)
                textureFile.closeFile()
            }
        }
        
        
        if let animPath = Bundle.main.path(forResource: "res.bundle/file_\(String.init(format: "%05d", num+4))", ofType: "pc") {
            if let animFile = FileHandle.init(forReadingAtPath: animPath) {
                package.merg(withFile: animFile)
                animFile.closeFile()
            }
        }
        
        if let gfModel = package.model {
            let model = Model.init(gfModel: gfModel)
            
            for gfTexture in package.textures {
                let texture = Texture.init(gfTexture: gfTexture)
                model.textureDict[gfTexture.name] = texture
            }
            
            for gfAnim in package.anims {
                let anim = Anim.init(gfAnim: gfAnim, bones: model.bones)
                model.anims.append(anim)
            }
            
            return model
        }
        return nil
    }
}
