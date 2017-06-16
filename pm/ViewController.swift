//
//  ViewController.swift
//  pm
//
//  Created by wanghuai on 2017/6/14.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadFile()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadFile() {
        let rootPath = Bundle.main.resourcePath
        let path = rootPath!+"/file_00001.pc"
        
        let file = FileHandle.init(forReadingAtPath: path)!
        print(file)
        let magicStr = file.readString(len: 4)
        file.seek(toFileOffset: 0)
        let magicNum = file.readUInt32()
        file.seek(toFileOffset: 0)
        
        print(magicStr, magicNum)
        
        let magic1 = file.readString(len: 1)
        let magic2 = file.readString(len: 1)
        
        if (magic1 < "A" || magic1 > "Z" || magic2 < "A" || magic2 > "Z")
        {
            return
        }
        
        let entries = file.readUInt16()
        let fileLenthAddr = UInt64(entries) * 4 + 4
        file.seek(toFileOffset: fileLenthAddr)
        if (UInt64(file.readUInt32()) != file.length())
        {
            return
        }
        file.seek(toFileOffset: 0)
        
        let package = GFPackage.init(withFile: file)
        print(package)
    }
}

