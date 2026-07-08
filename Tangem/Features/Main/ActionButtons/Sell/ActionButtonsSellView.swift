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

    var body: some View {
        TokenSelectorView(viewModel: viewModel.tokenSelectorViewModel) {
            TokenSelectorEmptyContentView(message: Localization.actionButtonsSellEmptySearchMessage)
        } headerContent: {
            notifications
        }
        .searchType(.native)
        .showsSeparators(false)
        .hidesSingleWalletName(true)
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: viewModel.notificationInput)
        .toolbar {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
        }
        .onAppear(perform: viewModel.onAppear)
        .accessibilityIdentifier(ActionButtonsAccessibilityIdentifiers.sellTokenSelectorScreen)
    }

    @ViewBuilder
    private var notifications: some View {
        if let notification = viewModel.notificationInput {
            NotificationView(input: notification)
                .transition(.notificationTransition)
        }
    }
}
