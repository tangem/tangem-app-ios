//
//  NewTokenSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemFoundation

struct NewTokenSelectorView: View {
    @ObservedObject var viewModel: NewTokenSelectorViewModel

    private var searchType: SearchType?

    init(viewModel: NewTokenSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        switch searchType {
        case .native:
            scrollView { scrollContent }
                .searchable(text: $viewModel.searchText)
                .keyboardType(.asciiCapable)
                .autocorrectionDisabled()
        case .custom:
            scrollView {
                CustomSearchBar(searchText: $viewModel.searchText, placeholder: Localization.commonSearch, style: .focused)

                scrollContent
            }
        case .none:
            scrollView { scrollContent }
        }
    }

    private func scrollView(@ViewBuilder content: @escaping () -> some View) -> some View {
        GroupedScrollView(spacing: 8, showsIndicators: false, content: content)
    }

    @ViewBuilder
    private var scrollContent: some View {
        ForEach(viewModel.wallets) {
            NewTokenSelectorWalletItemView(viewModel: $0, shouldShowSeparator: true)
        }

        FixedSpacer(height: 12)
    }
}

// MARK: - Setupable

extension NewTokenSelectorView: Setupable {
    func searchType(_ searchType: SearchType) -> Self {
        map { $0.searchType = searchType }
    }
}

extension NewTokenSelectorView {
    enum SearchType {
        case native
        case custom
    }
}
