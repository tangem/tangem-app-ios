//
//  GridViewModels.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct GridItemColor: Identifiable, Equatable {
    public let id: String
    public let color: Color

    public init(_ color: Color) {
        self.color = color
        id = color.description
    }
}

public struct GridItemImage: Identifiable, Equatable {
    public let id: String
    public let kind: GridItemImageKind

    public init(_ kind: GridItemImageKind) {
        self.kind = kind
        id = "\(kind.imageType.hashValue)"
    }
}

public enum GridItemImageKind: Equatable {
    case image(ImageType)
    case letter(ImageType)

    public var imageType: ImageType {
        switch self {
        case .image(let imageType): imageType
        case .letter(let imageType): imageType
        }
    }
}
