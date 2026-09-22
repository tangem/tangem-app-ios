//
//  FeedSearchView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct FeedSearchView: View {
    @ObservedObject var viewModel: FeedSearchViewModel

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Subviews

private extension FeedSearchView {
    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .suggestions(let history):
            CryptoSearchView(viewModel: viewModel.marketViewModel, showsResultBackground: false) {
                if !history.isEmpty {
                    FeedSearchRecentView(
                        queries: history.queries,
                        onSelectQuery: viewModel.onSelectRecentQuery,
                        onRemoveQuery: viewModel.onRemoveRecentQuery
                    )
                }
            }
            .padding(.top, FeedConstants.searchContentInset)

        case .tabs:
            FeedSearchTabsView(viewModel: viewModel.tabsViewModel)
        }
    }
}
