//
//  RelatedTokensSectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI

struct RelatedTokensSectionView: View {
    @ObservedObject var viewModel: RelatedTokensViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    var body: some View {
        redesignContent
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        VStack(alignment: .leading, spacing: .unit(.x3)) {
            redesignHeader

            redesignContentBody
        }
        .onAppear { viewModel.loadIfNeeded() }
    }

    private var redesignHeader: some View {
        Text(Localization.newsRelatedTokens)
            .style(Font.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
    }

    @ViewBuilder
    private var redesignContentBody: some View {
        switch viewModel.loadingState {
        case .idle, .loading:
            redesignLoadingSkeletons
        case .loaded:
            VStack(spacing: .unit(.x2)) {
                ForEach(viewModel.tokenViewModels) { tokenViewModel in
                    MarketTokenRowView(viewModel: tokenViewModel)
                        .background(
                            RoundedRectangle(cornerRadius: .unit(.x5), style: .continuous)
                                .fill(Color.Tangem.Surface.level3)
                        )
                }
            }
        case .error:
            redesignErrorView
        }
    }

    private var redesignErrorView: some View {
        TangemUnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: { viewModel.retry() }
        )
        .padding(.vertical, .unit(.x4))
    }

    private var redesignLoadingSkeletons: some View {
        VStack(spacing: .unit(.x2)) {
            ForEach(0 ..< 2, id: \.self) { _ in
                MarketsSkeletonItemView()
                    .background(
                        RoundedRectangle(cornerRadius: .unit(.x5), style: .continuous)
                            .fill(Color.Tangem.Surface.level3)
                    )
            }
        }
    }
}
