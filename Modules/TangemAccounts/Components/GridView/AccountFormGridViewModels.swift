//
//  GridViewModels.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct GridItemColor<ID: Hashable>: Identifiable, Equatable {
    public let id: ID
    public let color: Color

    public init(id: ID, color: Color) {
        self.id = id
        self.color = color
    }
}

public struct GridItemImage<ID: Hashable>: Identifiable, Equatable {
    public let id: ID
    public let kind: GridItemImageKind

    public init(id: ID, kind: GridItemImageKind) {
        self.id = id
        self.kind = kind
    }
}

public enum GridItemImageKind: Equatable {
    case image(ImageType)
    case letter(visualImageRepresentation: ImageType)

    public var imageType: ImageType {
        switch self {
        case .image(let imageType): imageType
        case .letter(let visualImageRepresentation): visualImageRepresentation
        }
    }
}
