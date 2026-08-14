//
//  TangemPayCashbackBlockedBanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayCashbackBlockedBanner: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Localization.tangempayCashbackDeactivatedTitle)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

                    Text(Localization.tangempayCashbackDeactivatedDescription)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                DesignSystem.Icons.Error.regular20.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconPrimary)
            }

            TangemUI.Button(
                label: Localization.commonGotIt,
                accessibilityLabel: nil,
                action: action
            )
            .size(.x9)
            .styleType(.secondary)
            .horizontalLayout(.infinity)
        }
        .padding(16)
        .background(DesignSystem.Color.bgStatusErrorSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

// MARK: - Previews

#Preview {
    TangemPayCashbackBlockedBanner(action: {})
        .padding(16)
}
