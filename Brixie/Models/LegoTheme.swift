//
//  LegoTheme.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Foundation
import SwiftData

@Model
final class LegoTheme {
    var id: Int
    var name: String
    var parentId: Int?
    var setCount: Int
    
    init(id: Int, name: String, parentId: Int? = nil, setCount: Int = 0) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.setCount = setCount
    }
}