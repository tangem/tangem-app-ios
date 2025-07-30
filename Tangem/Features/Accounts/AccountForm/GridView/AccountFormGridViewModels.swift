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
    let kind: GridItemImageKind

    init(_ kind: GridItemImageKind) {
        self.kind = kind
        id = "\(kind.imageType.hashValue)"
    }
}

enum GridItemImageKind: Equatable {
    case image(ImageType)
    case letter(ImageType)

    var imageType: ImageType {
        switch self {
        case .image(let imageType): imageType
        case .letter(let imageType): imageType
        }
    }
}
