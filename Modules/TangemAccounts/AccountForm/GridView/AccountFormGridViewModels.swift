//
//  GridViewModels.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct GridItemColor: Identifiable, Equatable {
    let id: String
    let color: Color

    init(_ color: Color) {
        self.color = color
        id = color.description
    }
}

struct GridItemImage: Identifiable, Equatable {
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
