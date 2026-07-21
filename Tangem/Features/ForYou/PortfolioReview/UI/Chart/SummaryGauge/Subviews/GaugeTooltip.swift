//
//  GaugeTooltip.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct GaugeTooltip: View {
    let title: String
    let value: String
    let percent: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)

            HStack(spacing: 0) {
                Text(value)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)

                Text("  \(AppConstants.dotSign)  " + percent)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .tangemMaterialSurface(in: Capsule())
    }
}
