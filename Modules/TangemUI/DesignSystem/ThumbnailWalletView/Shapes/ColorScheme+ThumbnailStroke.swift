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
        guard self == .dark else {
            return nil
        }

        return .init(
            color: Color.Tangem.CardCollection.border,
            style: .init(lineWidth: width)
        )
    }
}
