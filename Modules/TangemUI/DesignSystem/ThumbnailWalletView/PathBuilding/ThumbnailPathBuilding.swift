//
//  ThumbnailPathBuilding.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

protocol ThumbnailPathBuilding {
    associatedtype FillColors
    static func build(for size: CGSize, with colors: FillColors, colorScheme: ColorScheme) -> [ThumbnailPathFillMode]
}
