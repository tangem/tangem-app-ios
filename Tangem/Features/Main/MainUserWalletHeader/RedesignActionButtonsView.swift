//
//  RedesignActionButtonsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct RedesignActionButtonsView: View {
    @ObservedObject var viewModel: ActionButtonsViewModel

    @ScaledMetric private var spacing: CGFloat = .unit(.x3)
    @ScaledMetric private var horizontalPadding: CGFloat = .unit(.x15)

    private var dynamicHorizontalPadding: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let defaultScreenWidth: CGFloat = 390
        return horizontalPadding * screenWidth / defaultScreenWidth
    }

    var body: some View {
        let visibility = viewModel.actionButtonsVisibility

        HStack(alignment: .top, spacing: spacing) {
            if visibility.isExchangeVisible {
                RedesignActionButtonView(viewModel: viewModel.buyActionButtonViewModel)
                    .frame(maxWidth: .infinity)
            }

            if visibility.isSwappingVisible {
                RedesignActionButtonView(viewModel: viewModel.swapActionButtonViewModel)
                    .frame(maxWidth: .infinity)
            }

            if visibility.isExchangeVisible {
                RedesignActionButtonView(viewModel: viewModel.sellActionButtonViewModel)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, dynamicHorizontalPadding)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(TokenAccessibilityIdentifiers.actionButtonsList)
    }
}
