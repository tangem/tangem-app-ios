//
//  ActionButtonsBuyView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemFoundation
import TangemAccessibilityIdentifiers

struct ActionButtonsBuyView: View {
    @ObservedObject var viewModel: ActionButtonsBuyViewModel

    private var backgroundColor: Color {
        return Color.Tangem.Surface.level2
    }

    var body: some View {
        Group {
            redesignSelector
        }
        .accessibilityIdentifier(ActionButtonsAccessibilityIdentifiers.buyTokenSelectorTokensList)
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
        }
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var redesignSelector: some View {
        TokenSelectorView(
            viewModel: viewModel.tokenSelectorViewModel,
            emptyContentView: {
                if viewModel.shouldShowSearchEmptyContent {
                    TokenSelectorEmptyContentView(message: Localization.actionButtonsBuyEmptySearchMessage)
                }
            },
            additionalContent: {
                if let pulseMarketWidgetViewModel = viewModel.pulseMarketWidgetViewModel {
                    PulseMarketWidgetViewRedesign(
                        viewModel: pulseMarketWidgetViewModel,
                        showsSeeAllButton: false
                    )
                    .padding(.top, 8)
                }
            }
        )
        .sectionHeader(.init(title: Localization.marketsSearchPortfolioHeader))
        .searchType(.native)
        .showsSeparators(false)
        .hidesSingleWalletName(true)
        .navigationTitle(Localization.commonChooseToken)
    }
}
