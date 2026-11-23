//
//  EarnIllustrationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct EarnIllustrationView: View {
    let illustration: ImageType

    @ScaledMetric private var slotDimension: CGFloat = 40
    @ScaledMetric private var canvasDimension: CGFloat = 64

    var body: some View {
        illustration.image
            .resizable()
            .scaledToFit()
            .foregroundStyle(DesignSystem.Color.iconAccentBlue)
            .frame(size: CGSize(bothDimensions: canvasDimension))
            .frame(size: CGSize(bothDimensions: slotDimension))
            .accessibilityHidden(true)
    }
}
