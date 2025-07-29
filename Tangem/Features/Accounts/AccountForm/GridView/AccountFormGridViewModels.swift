//
//  GridViewModels.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

protocol SelectableGridItem: Identifiable, Equatable {
    var id: String { get }
}

struct GridItemColor: SelectableGridItem {
    let id: String
    let color: Color

    init(_ color: Color) {
        self.color = color
        id = color.description
    }
}

struct GridItemImage: SelectableGridItem {
    let id: String
    let imageType: ImageType

    init(_ imageType: ImageType) {
        self.imageType = imageType
        id = "\(imageType.hashValue)"
    }
}
