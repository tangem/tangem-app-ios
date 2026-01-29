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
    private var sectionHeaderConfiguration: SectionHeaderConfiguration?

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
        GroupedScrollView(contentType: .lazy(spacing: 8)) {
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
        case .visible(let itemsCount):
            if let sectionHeaderConfiguration {
                sectionHeader(configuration: sectionHeaderConfiguration, itemsCount: itemsCount)
            }

            LazyVStack(spacing: 8) {
                ForEach(viewModel.wallets) { AccountsAwareTokenSelectorWalletItemView(viewModel: $0) }
            }
            .transition(.opacity.animation(.easeInOut))
        }

        additionalContent

        FixedSpacer(height: 12)
    }

    private func sectionHeader(configuration: SectionHeaderConfiguration, itemsCount: Int) -> some View {
        let showCount = configuration.showsItemsCount && !viewModel.searchText.isEmpty && itemsCount > 0

        return HStack(spacing: 8) {
            Text(configuration.title)
                .style(Fonts.BoldStatic.title3, color: Colors.Text.primary1)

            if showCount {
                Text("\(itemsCount)")
                    .style(Fonts.BoldStatic.title3, color: Colors.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }
}

// MARK: - Setupable

extension AccountsAwareTokenSelectorView: Setupable {
    func searchType(_ searchType: SearchType) -> Self {
        map { $0.searchType = searchType }
    }

    func sectionHeader(_ configuration: SectionHeaderConfiguration) -> Self {
        map { $0.sectionHeaderConfiguration = configuration }
    }
}

extension AccountsAwareTokenSelectorView {
    enum SearchType {
        case native
        case custom
    }

    struct SectionHeaderConfiguration {
        let title: String
        let showsItemsCount: Bool

        init(title: String, showsItemsCount: Bool = false) {
            self.title = title
            self.showsItemsCount = showsItemsCount
        }
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
