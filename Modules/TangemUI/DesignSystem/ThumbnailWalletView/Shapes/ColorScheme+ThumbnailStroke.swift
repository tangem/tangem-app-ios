//
//  ColorScheme+ThumbnailStroke.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension ColorScheme {
    func stroke(
        width: CGFloat
    ) -> ThumbnailPathFillMode.Stroke? {
        .init(
            color: Color.Tangem.CardCollection.border,
            style: .init(lineWidth: width)
        )
    }

    var defaultStroke: ThumbnailPathFillMode.Stroke {
        .init(
            color: Color.Tangem.CardCollection.border,
            style: .init(lineWidth: 1.0)
        )
    }
}
