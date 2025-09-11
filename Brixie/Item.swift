//
//  LegoSet.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Foundation
import SwiftData

@Model
final class LegoSet {
    var setNum: String
    var name: String
    var year: Int
    var themeId: Int
    var themeName: String?
    var numParts: Int
    var imageURL: String?
    var isFavorite: Bool
    var lastViewed: Date?
    var cachedImageData: Data?
    
    init(
        setNum: String,
        name: String,
        year: Int,
        themeId: Int,
        numParts: Int,
        imageURL: String? = nil,
        themeName: String? = nil
    ) {
        self.setNum = setNum
        self.name = name
        self.year = year
        self.themeId = themeId
        self.themeName = themeName
        self.numParts = numParts
        self.imageURL = imageURL
        self.isFavorite = false
        self.lastViewed = nil
        self.cachedImageData = nil
    }
}
