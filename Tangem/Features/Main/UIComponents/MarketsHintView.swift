//
//  MarketsHintView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct MarketsHintView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text(Localization.marketsHintPartOne)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

            HStack(spacing: 4) {
                Text(Localization.marketsHintPartTwo)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

                Assets.Glyphs.tripleSparkles.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .frame(width: 20, height: 20)
            }
        }
    }
}
