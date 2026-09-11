//
//  ForYouAddFundsTokenSelectorView+RowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

extension ForYouAddFundsTokenSelectorView {
    struct RowView: View {
        let data: ForYouAddFundsTokenSelectorViewModel.RowData

        @ScaledMetric private var iconSize: CGFloat = 40

        var body: some View {
            Row(
                title: data.name,
                subtitle: data.network
            )
            .valueAccessory {
                balanceText(data.fiat, font: DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            }
            .subvalueAccessory {
                balanceText(data.crypto, font: DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .start { icon }
            .contentShape(Rectangle())
            .onTapGesture(perform: data.onTap)
            .accessibilityAddTraits(.isButton)
        }
    }
}

private extension ForYouAddFundsTokenSelectorView.RowView {
    var icon: some View {
        TokenIcon(
            tokenIconInfo: data.tokenIconInfo,
            size: CGSize(bothDimensions: iconSize)
        )
    }

    /// Maskable balance; `nil` stays a plain dash — "no data" must not look like "hidden".
    func balanceText(_ value: String?, font: TangemTypographyToken, color: Color) -> some View {
        Group {
            if let value {
                SensitiveText(value)
            } else {
                Text(AppConstants.enDashSign)
            }
        }
        .style(font, color: color)
        .lineLimit(1)
    }
}
