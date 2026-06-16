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
        if FeatureProvider.isAvailable(.redesign) {
            redesignContent
        } else {
            legacyContent
        }
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
            .style(.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
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

    // MARK: - Legacy

    private var legacyContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            legacyHeaderView

            legacyContentInner
                .defaultRoundedBackground(
                    with: Color.Tangem.Surface.level3,
                    verticalPadding: .zero,
                    horizontalPadding: .zero
                )
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }

    private var legacyHeaderView: some View {
        Text(Localization.newsRelatedTokens)
            .style(Fonts.Bold.title3, color: Color.Tangem.Text.Neutral.primary)
    }

    @ViewBuilder
    private var legacyContentInner: some View {
        switch viewModel.loadingState {
        case .idle, .loading:
            legacyLoadingSkeletons
        case .loaded:
            VStack(spacing: .zero) {
                ForEach(viewModel.tokenViewModels) {
                    MarketTokenItemView(viewModel: $0, cellWidth: mainWindowSize.width)
                }
            }
        case .error:
            legacyErrorView
        }
    }

    private var legacyErrorView: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: { viewModel.retry() }
        )
        .padding(.vertical, 16)
    }

    private var legacyLoadingSkeletons: some View {
        ForEach(0 ..< 2, id: \.self) { _ in
            MarketsSkeletonItemView()
        }
    }
}
