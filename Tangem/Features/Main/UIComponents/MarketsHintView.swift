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
    @Environment(\.isRedesign) var isRedesign

    var body: some View {
        if isRedesign {
            redesignBody
        } else {
            legacyBody
        }
    }

    private var redesignBody: some View {
        VStack(spacing: 4) {
            Text(Localization.marketsHintPartOne)
                .style(DesignSystem.Font.subheadingMediumToken, color: .Tangem.Text.Neutral.primary)

            HStack(spacing: 4) {
                Text(Localization.marketsHintPartTwo)
                    .style(DesignSystem.Font.subheadingMediumToken, color: .Tangem.Text.Neutral.tertiary)

                Assets.Glyphs.tripleSparkles.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiary)
                    .frame(width: 20, height: 20)
            }
        }
    }

    private var legacyBody: some View {
        VStack(spacing: 8) {
            Text(Localization.marketsHint)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .style(Fonts.Regular.footnote, color: Colors.Icon.informative)

            Assets.chevronDown12.image
        }
        .padding(.top, 28)
        .padding(.bottom, 8)
        .frame(width: 162)
    }
}
