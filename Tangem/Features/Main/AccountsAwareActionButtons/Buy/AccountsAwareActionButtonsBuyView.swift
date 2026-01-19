//
//  AccountsAwareActionButtonsBuyView.swift
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

struct AccountsAwareActionButtonsBuyView: View {
    @ObservedObject var viewModel: AccountsAwareActionButtonsBuyViewModel

    var body: some View {
        AccountsAwareTokenSelectorView(
            viewModel: viewModel.tokenSelectorViewModel,
            emptyContentView: {
                AccountsAwareTokenSelectorEmptyContentView(message: Localization.actionButtonsBuyEmptySearchMessage)
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
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationTitle(Localization.commonBuy)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
        }
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.alert) { $0.alert }
    }
}
