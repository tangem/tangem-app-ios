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

struct ThumbnailPathBuilderView<Builder: ThumbnailPathBuilding>: View {
    let colors: Builder.FillColors
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            let parts = Builder.build(for: size, with: colors, colorScheme: colorScheme)
            buildFilledThumbnailShape(context: context, parts: parts)
        }
    }
}
