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
        GroupedScrollView(spacing: 8, showsIndicators: false) {
            if searchType == .custom {
                CustomSearchBar(
                    searchText: $viewModel.searchText,
                    placeholder: Localization.commonSearch
                )
            }

            content
        }
        .if(searchType == .native) {
            $0
                .searchable(text: $viewModel.searchText)
                .autocorrectionDisabled()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .empty:
            NewTokenSelectorViewEmptyContent(message: Localization.nftEmptySearch)
        case .wallets(let wallets):
            ForEach(wallets) {
                NewTokenSelectorGroupedSectionView(viewModel: $0)
            }
        case .walletsWithAccounts(let walletsWithAccounts):
            ForEach(walletsWithAccounts) { viewModel in
                let isNotLast = walletsWithAccounts.last?.id != viewModel.id
                NewTokenSelectorGroupedSectionWrapperView(viewModel: viewModel, shouldShowSeparator: isNotLast)
            }
        }
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
