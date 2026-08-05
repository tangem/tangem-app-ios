//
//  MarketsTokenSearchItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsTokenSearchItemView: View {
    @ScaledMetric private var tokensSpacing: CGFloat = 8
    @ScaledMetric private var retrySpacing: CGFloat = 8

    private let retryTopPadding: CGFloat = 40
    private let tokenBackgroundCornerRadius: CGFloat = 20

    let item: MarketsTokenSearchViewModel.MarketItem

    private var isLoading: Bool {
        item.state == .loading
    }

    private var isRetry: Bool {
        item.state == .retry
    }

    private var showTokensUnderCap: Bool {
        item.underCapItem.isShown
    }

    var body: some View {
        LazyVStack(spacing: tokensSpacing) {
            ForEach(item.models) {
                tokenView(model: $0)
            }

            if isLoading {
                loadingView()
            } else if isRetry {
                retryView(item: item.retryItem)
                    .padding(.top, retryTopPadding)
            }

            if showTokensUnderCap {
                MarketsTokensUnderCapView(onShowUnderCapAction: item.underCapItem.action)
            }
        }
    }
}

// MARK: - Subviews

private extension MarketsTokenSearchItemView {
    func tokenView(model: MarketsItemViewModel) -> some View {
        MarketTokenRowView(viewModel: model.tokenItemViewModel)
            .roundedBackground(
                with: DesignSystem.Color.bgSecondary,
                padding: .zero,
                radius: tokenBackgroundCornerRadius
            )
            .onAppear {
                model.onAppear()
            }
            .onDisappear {
                model.onDisappear()
            }
    }

    func loadingView() -> some View {
        VStack(spacing: tokensSpacing) {
            ForEach(0 ..< 3) { _ in
                TangemTwoLineRowSkeletonView()
                    .roundedBackground(
                        with: DesignSystem.Color.bgSecondary,
                        padding: .zero,
                        radius: tokenBackgroundCornerRadius
                    )
            }
        }
    }

    func retryView(item: MarketsTokenSearchViewModel.MarketItem.RetryItem) -> some View {
        TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: item.action)
    }
}
