//
//  PriceAlertsOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// Skeleton: layout/strings are placeholders until [REDACTED_INFO].
struct PriceAlertsOnboardingView: View {
    @ObservedObject var viewModel: PriceAlertsOnboardingViewModel

    var body: some View {
        VStack(spacing: 16) {
            DesignSystem.Icons.Bell.regular28.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.accent)

            // [REDACTED_TODO_COMMENT]
            Text("Token added to watchlist")
                .style(Fonts.Bold.title3, color: Colors.Text.primary1)

            Text("you will receive price alerts")
                .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)

            Button(action: viewModel.gotItAction) {
                Text("Got it")
            }
        }
        .multilineTextAlignment(.center)
        .padding(16)
    }
}
