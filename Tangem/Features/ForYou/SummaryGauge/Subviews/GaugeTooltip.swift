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
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)

            HStack(spacing: 4) {
                Text(value)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)

                Circle()
                    .fill(DesignSystem.Color.iconTertiary)
                    .frame(width: 3, height: 3)

                Text(percent)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .tangemMaterialSurface(in: Capsule())
    }
}
