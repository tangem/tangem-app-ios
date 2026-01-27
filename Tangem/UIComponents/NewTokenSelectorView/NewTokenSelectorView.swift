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

struct NewTokenSelectorView<EmptyContentView: View>: View {
    @ObservedObject var viewModel: NewTokenSelectorViewModel
    private let emptyContentView: EmptyContentView

    private var searchType: SearchType?

    init(
        viewModel: NewTokenSelectorViewModel,
        @ViewBuilder emptyContentView: () -> EmptyContentView
    ) {
        self.viewModel = viewModel

        self.emptyContentView = emptyContentView()
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
        GroupedScrollView(contentType: .lazy(spacing: 8), content: content)
            .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var scrollContent: some View {
        switch viewModel.contentVisibility {
        case .empty:
            emptyContentView
        case .visible:
            if let wallets = viewModel.wallets {
                ForEach(wallets) {
                    NewTokenSelectorWalletItemView(viewModel: $0)
                }
                .transition(.opacity.animation(.easeInOut))
            }
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
