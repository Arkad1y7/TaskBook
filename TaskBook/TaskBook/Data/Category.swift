//
//  Category.swift
//  TaskBook
//
//  Created by Аркадий Шахмелян on 29.08.2023.
//

import Foundation
import RealmSwift

class Category: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var color: String = ""
    let items = List<Item>()
}
