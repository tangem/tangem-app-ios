//
//  FeedSearchView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

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
            CryptoSearchView(viewModel: viewModel.marketViewModel) {
                if !history.isEmpty {
                    FeedSearchRecentView(
                        queries: history.queries,
                        onSelectQuery: viewModel.onSelectRecentQuery,
                        onRemoveQuery: viewModel.onRemoveRecentQuery
                    )
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear
                    .frame(height: FeedConstants.searchContentInset)
                    .allowsHitTesting(false)
            }
            .reverseMask(alignment: .top) {
                FeedTopFade(height: Constants.fadeHeight, visibleHeight: Constants.visibleFadeHeight)
            }

        case .tabs:
            FeedSearchTabsView(viewModel: viewModel.tabsViewModel)
        }
    }
}

// MARK: - Constants

private extension FeedSearchView {
    enum Constants {
        // Keep the 32 pt gradient below the hard fade's 56 pt solid header.
        static let fadeHeight: CGFloat = 88
        static let visibleFadeHeight: CGFloat = 32
    }
}
