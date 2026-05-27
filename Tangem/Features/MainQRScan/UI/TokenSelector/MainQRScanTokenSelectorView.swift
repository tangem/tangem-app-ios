//
//  MainQRScanTokenSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct MainQRScanTokenSelectorView: View {
    @ObservedObject var viewModel: MainQRScanTokenSelectorViewModel
    @ObservedObject private var tokenSelectorViewModel: TokenSelectorViewModel

    init(viewModel: MainQRScanTokenSelectorViewModel) {
        self.viewModel = viewModel
        _tokenSelectorViewModel = ObservedObject(wrappedValue: viewModel.tokenSelectorViewModel)
    }

    var body: some View {
        GroupedScrollView(contentType: .lazy(spacing: 8.0)) {
            content
                .animation(.easeInOut, value: tokenSelectorViewModel.contentVisibility)
        }
        .searchable(
            text: $tokenSelectorViewModel.searchText,
            placement: searchFieldPlacement,
            prompt: Localization.commonSearchTokens
        )
        .keyboardType(.asciiCapable)
        .autocorrectionDisabled()
        .scrollDismissesKeyboard(.interactively)
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .navigationTitle(Localization.commonTokenSend)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.close)
        }
    }

    @ViewBuilder
    private var content: some View {
        let compatibleWallets = tokenSelectorViewModel.wallets.filter(\.hasCompatibleItems)

        switch tokenSelectorViewModel.contentVisibility {
        case .loading:
            TokenSelectorLoadingView()
        case .empty:
            noResultsView
        case .visible:
            if compatibleWallets.isEmpty {
                noResultsView
            } else {
                let isAccountsMode = tokenSelectorViewModel.wallets.contains(where: \.hasMultipleAccounts)

                ForEach(compatibleWallets) { wallet in
                    MainQRScanTokenSelectorWalletItemView(
                        viewModel: wallet,
                        isAccountsMode: isAccountsMode,
                        accountsModeSingleWalletHeader: viewModel.accountsModeHeader(for: wallet)
                    )
                }
            }
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 0.0) {
            Spacer(minLength: 220.0)

            Text(Localization.commonNoResults)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0.0)
        }
    }

    private var searchFieldPlacement: SearchFieldPlacement {
        if #available(iOS 26.0, *) {
            return .automatic
        }

        return .navigationBarDrawer(displayMode: .always)
    }
}
