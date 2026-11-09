//
//  TangemPayReplacingCardBanner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct TangemPayReplacingCardBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(DesignSystem.Color.iconAccentBlue)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.tangempayReissueCardInProgress)
                    .style(Fonts.Bold.footnote, color: DesignSystem.Color.textPrimary)

                Text(Localization.tangempayReissueCardInProgressDescription)
                    .style(Fonts.Regular.caption1, color: DesignSystem.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(14)
    }
}
