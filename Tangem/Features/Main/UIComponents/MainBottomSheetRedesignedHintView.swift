//
//  MainBottomSheetRedesignedHintView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct MainBottomSheetRedesignedHintView: View {
    let offset: CGFloat
    let isActive: Bool

    var body: some View {
        Group {
            if isActive {
                VStack(spacing: .unit(.x1)) {
                    Text(Localization.marketsHintPartOne)
                        .style(.Tangem.Body15.regular, color: .Tangem.Text.Neutral.primary)

                    HStack(spacing: .unit(.x1)) {
                        Text(Localization.marketsHintPartTwo)
                            .style(.Tangem.Body15.regular, color: .Tangem.Text.Neutral.tertiary)

                        Assets.Glyphs.tripleSparkles.image
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiary)
                            .frame(width: .unit(.x5), height: .unit(.x5))
                    }
                }
                .transition(.opacity)
            }
        }
        .offset(y: offset)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}
