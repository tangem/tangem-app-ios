//
//  PriceAlertsOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct PriceAlertsOnboardingView: View {
    @ObservedObject var viewModel: PriceAlertsOnboardingViewModel

    var body: some View {
        BottomSheetErrorContentView(
            icon: .init(
                icon: DesignSystem.Icons.Bell.regular28,
                overlay: Colors.Icon.accent,
                tint: Colors.Icon.accent
            ),
            // [REDACTED_TODO_COMMENT]
            title: "Token added to watchlist",
            subtitle: "you will receive price alerts",
            closeAction: viewModel.closeAction,
            primaryButton: MainButton.Settings(title: Localization.commonGotIt, action: viewModel.gotItAction)
        )
    }
}
