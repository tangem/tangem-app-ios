//
//  TangemPayMoneyAccountBalanceUnavailableBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemFoundation
import TangemLocalization

struct TangemPayMoneyAccountBalanceUnavailableBannerView: View {
    var body: some View {
        MessageBanner(
            title: Localization.moneyAccountBalanceUnavailableTitle,
            description: Localization.moneyAccountBalanceUnavailableDescription
        )
        .glowRing(.error)
        .slotEnd {
            DesignSystem.Icons.Error.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
        }
    }
}

// MARK: - Previews

#Preview {
    TangemPayMoneyAccountBalanceUnavailableBannerView()
}
