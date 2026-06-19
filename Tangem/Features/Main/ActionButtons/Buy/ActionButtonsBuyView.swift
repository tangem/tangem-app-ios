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
        if FeatureProvider.isAvailable(.redesign) {
            return Color.Tangem.Surface.level2
        }
        return Colors.Background.tertiary
    }

    var body: some View {
        Group {
            if FeatureProvider.isAvailable(.redesign) {
                redesignSelector
            } else {
                legacySelector
            }
        }
        .accessibilityIdentifier(ActionButtonsAccessibilityIdentifiers.buyTokenSelectorTokensList)
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle(Localization.swappingToTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
        }
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var legacySelector: some View {
        TokenSelectorView(
            viewModel: viewModel.tokenSelectorViewModel,
            emptyContentView: {
                TokenSelectorEmptyContentView(message: Localization.actionButtonsBuyEmptySearchMessage)
            },
            additionalContent: {
                if viewModel.hotCryptoItems.isNotEmpty {
                    HotCryptoView(
                        items: viewModel.hotCryptoItems,
                        action: viewModel.userDidTapHotCryptoToken
                    )
                }
            }
        )
        .searchType(.native)
        .accessibilityIdentifier(ActionButtonsAccessibilityIdentifiers.buyTokenSelectorTokensList)
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationTitle(Localization.swappingToTitle)
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
                TokenSelectorEmptyContentView(message: Localization.actionButtonsBuyEmptySearchMessage)
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
    }
}
