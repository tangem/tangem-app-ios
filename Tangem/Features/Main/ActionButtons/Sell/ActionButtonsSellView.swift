//
//  ActionButtonsSellView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct ActionButtonsSellView: View {
    @ObservedObject var viewModel: ActionButtonsSellViewModel

    private var navigationTitle: String {
        if FeatureProvider.isAvailable(.redesign) {
            return Localization.swappingTokenListTitle
        }
        return Localization.commonSell
    }

    private var backgroundColor: Color {
        FeatureProvider.isAvailable(.redesign) ? .Tangem.Surface.level2 : Colors.Background.tertiary
    }

    var body: some View {
        TokenSelectorView(viewModel: viewModel.tokenSelectorViewModel) {
            TokenSelectorEmptyContentView(message: Localization.actionButtonsSellEmptySearchMessage)
        } headerContent: {
            headerContent
        }
        .searchType(.native)
        .showsSeparators(false)
        .hidesSingleWalletName(true)
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: viewModel.notificationInput)
        .toolbar {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
        }
        .onAppear(perform: viewModel.onAppear)
        .accessibilityIdentifier(ActionButtonsAccessibilityIdentifiers.sellTokenSelectorScreen)
    }

    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let notification = viewModel.notificationInput {
                NotificationView(input: notification)
                    .transition(.notificationTransition)
            }

            Text(Localization.marketsSearchPortfolioHeader)
                .style(.Tangem.Heading20.semibold.font, color: .Tangem.Text.Neutral.primary)
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
