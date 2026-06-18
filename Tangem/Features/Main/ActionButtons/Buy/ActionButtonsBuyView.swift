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

    var body: some View {
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
}
