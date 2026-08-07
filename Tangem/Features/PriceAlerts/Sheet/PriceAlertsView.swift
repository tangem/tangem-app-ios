//
//  PriceAlertsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PriceAlertsView: View {
    @ObservedObject var viewModel: PriceAlertsViewModel

    var body: some View {
        ZStack {
            switch viewModel.viewState {
            case .onboarding(let viewModel):
                PriceAlertsOnboardingView(viewModel: viewModel)

            case .walletSelector(let viewModel):
                PriceAlertsWalletSelectorView(viewModel: viewModel)

            case .none:
                EmptyView()
            }
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}
