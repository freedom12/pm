//
//  DataMgr.swift
//  pm
//
//  Created by wanghuai on 2017/7/5.
//  Copyright © 2017年 wanghuai. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class DataMgr:NSObject {
    static let sharedInstance = DataMgr()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        //xcdatamodeld编译后为momd
        let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        var fileManager = FileManager.default
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let url = urls[urls.count-1] as URL
        //sqlite的库路径
        var storeURL = url.appendingPathComponent("mp.sqlite")
        //应用程序沙箱目录中的sqlite文件是否已经存在,如果它不存在(即应用程序第一次运行),则将包中的sqlite文件复制到沙箱文件目录。即加载初始化库数据
        //若想重新在模拟器（simulator）中重新使用该sqlite初始化，点击IOS Simulator->Reset Contents and Settings，重置模拟器即可
        if !fileManager.fileExists(atPath: storeURL.path) {
            var copyURL = Bundle.main.url(forResource: "pm", withExtension: "sqlite")!
            try! fileManager.copyItem(at: copyURL, to: storeURL)
        }
        //NSMigratePersistentStoresAutomaticallyOption是否自动迁移数据，
        //NSInferMappingModelAutomaticallyOption是否自动创建映射模型
        var options = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]
        // 根据managedObjectModel创建coordinator
        var coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        // 指定持久化存储的数据类型，默认的是NSSQLiteStoreType，即SQLite数据库
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        }
        catch
        {
            print("Unresolved error \(String(describing: error))")
            abort()
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()
    
}
