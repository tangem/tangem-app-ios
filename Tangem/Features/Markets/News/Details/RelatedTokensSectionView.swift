//
//  RelatedTokensSectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct RelatedTokensSectionView: View {
    @ObservedObject var viewModel: RelatedTokensViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            content
                .defaultRoundedBackground(
                    with: Color.Tangem.Surface.level4,
                    verticalPadding: .zero,
                    horizontalPadding: .zero
                )
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        Text(Localization.newsRelatedTokens)
            .style(Fonts.Bold.title3, color: Color.Tangem.Text.Neutral.primary)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadingState {
        case .idle, .loading:
            loadingSkeletons
        case .loaded:
            VStack(spacing: .zero) {
                ForEach(viewModel.tokenViewModels) {
                    MarketTokenItemView(viewModel: $0, cellWidth: mainWindowSize.width)
                }
            }
        case .error:
            EmptyView()
        }
    }

    // MARK: - Loading Skeletons

    private var loadingSkeletons: some View {
        ForEach(0 ..< 2, id: \.self) { _ in
            MarketsSkeletonItemView()
        }
    }
}
