//
//  EarnAccountItemView+RewardText.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

extension EarnAccountItemView {
    /// "+ {amount}/year" with only the amount maskable; `nil` stays a plain dash — "no data" must not look like "hidden".
    struct RewardText: View {
        let amount: String?

        var body: some View {
            rewardText
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
        }

        @ViewBuilder
        private var rewardText: some View {
            if let amount {
                SensitiveText(builder: Self.template, sensitive: amount)
            } else {
                Text(AppConstants.enDashSign)
            }
        }

        private static func template(_ amount: String) -> String {
            "\(AppConstants.plusSign) \(Localization.forYouEarnPerYear(amount))"
        }
    }
}
