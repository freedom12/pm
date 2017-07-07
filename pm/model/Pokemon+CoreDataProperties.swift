//
//  Pokemon+CoreDataProperties.swift
//  pm
//
//  Created by wanghuai on 2017/7/5.
//  Copyright © 2017年 wanghuai. All rights reserved.
//
//

import Foundation
import CoreData


extension Pokemon {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pokemon> {
        return NSFetchRequest<Pokemon>(entityName: "Pokemon")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: Int64

}
