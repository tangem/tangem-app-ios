//
//  AccountsAwareTokenSelectorView.swift
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

struct AccountsAwareTokenSelectorView<EmptyContentView: View, AdditionalContentView: View>: View {
    @ObservedObject var viewModel: AccountsAwareTokenSelectorViewModel
    private let emptyContentView: EmptyContentView
    private let additionalContent: AdditionalContentView

    private var searchType: SearchType?

    init(
        viewModel: AccountsAwareTokenSelectorViewModel,
        @ViewBuilder emptyContentView: () -> EmptyContentView,
        @ViewBuilder additionalContent: () -> AdditionalContentView
    ) {
        self.viewModel = viewModel
        self.emptyContentView = emptyContentView()
        self.additionalContent = additionalContent()
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
                CustomSearchBar(
                    searchText: $viewModel.searchText,
                    placeholder: Localization.commonSearch,
                    style: .focused
                )

                scrollContent
            }
        case .none:
            scrollView { scrollContent }
        }
    }

    private func scrollView(@ViewBuilder content: @escaping () -> some View) -> some View {
        GroupedScrollView(contentType: .plain(spacing: 8)) {
            content()
                .animation(.easeInOut, value: viewModel.contentVisibility)
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        switch viewModel.contentVisibility {
        case .empty:
            emptyContentView
                .transition(.move(edge: .top).combined(with: .opacity).animation(.easeInOut))
        case .visible:
            LazyVStack(spacing: 8) {
                ForEach(viewModel.wallets) { AccountsAwareTokenSelectorWalletItemView(viewModel: $0) }
            }
            .transition(.opacity.animation(.easeInOut))
        }

        additionalContent

        FixedSpacer(height: 12)
    }
}

// MARK: - Setupable

extension AccountsAwareTokenSelectorView: Setupable {
    func searchType(_ searchType: SearchType) -> Self {
        map { $0.searchType = searchType }
    }
}

extension AccountsAwareTokenSelectorView {
    enum SearchType {
        case native
        case custom
    }
}

// MARK: - Convenience init

extension AccountsAwareTokenSelectorView where AdditionalContentView == EmptyView {
    init(
        viewModel: AccountsAwareTokenSelectorViewModel,
        @ViewBuilder emptyContentView: () -> EmptyContentView
    ) {
        self.viewModel = viewModel
        self.emptyContentView = emptyContentView()
        additionalContent = EmptyView()
    }
}
