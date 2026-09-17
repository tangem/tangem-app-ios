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
        case .recent(let history):
            ScrollView {
                if !history.isEmpty {
                    FeedSearchRecentView(
                        history: history,
                        onSelectToken: viewModel.onSelectRecentToken,
                        onSelectQuery: viewModel.onSelectRecentQuery,
                        onRemoveQuery: viewModel.onRemoveRecentQuery,
                        onClear: viewModel.onClearRecent
                    )
                    .padding(.vertical, Constants.contentVerticalInset)
                }
            }
            .scrollIndicators(.hidden)
            .padding(.top, FeedConstants.searchContentInset)

        case .tabs:
            FeedSearchTabsView(viewModel: viewModel.tabsViewModel)
        }
    }
}

// MARK: - Constants

private extension FeedSearchView {
    enum Constants {
        static let contentVerticalInset: CGFloat = 8
    }
}
