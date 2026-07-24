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
import TangemUIUtils

struct RelatedTokensSectionView: View {
    @ObservedObject var viewModel: RelatedTokensViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    var body: some View {
        redesignContent
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            redesignHeader

            redesignContentBody
        }
        .onAppear { viewModel.loadIfNeeded() }
    }

    private var redesignHeader: some View {
        Text(Localization.newsRelatedTokens)
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
    }

    @ViewBuilder
    private var redesignContentBody: some View {
        switch viewModel.loadingState {
        case .idle, .loading:
            redesignLoadingSkeletons
        case .loaded:
            VStack(spacing: 8) {
                ForEach(viewModel.tokenViewModels) { tokenViewModel in
                    MarketTokenRowView(viewModel: tokenViewModel)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(DesignSystem.Color.bgSecondary)
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
        .padding(.vertical, 16)
    }

    private var redesignLoadingSkeletons: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 2, id: \.self) { _ in
                MarketsSkeletonItemView()
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(DesignSystem.Color.bgSecondary)
                    )
            }
        }
    }
}
