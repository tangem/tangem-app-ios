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

struct AccountsAwareActionButtonsBuyView: View {
    @ObservedObject var viewModel: AccountsAwareActionButtonsBuyViewModel

    var body: some View {
        AccountsAwareTokenSelectorView(viewModel: viewModel.tokenSelectorViewModel) {
            AccountsAwareTokenSelectorEmptyContentView(message: Localization.actionButtonsBuyEmptySearchMessage)
        }
        .searchType(.native)
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationTitle(Localization.commonBuy)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                CircleButton.close(action: viewModel.close)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.alert) { $0.alert }
    }
}
