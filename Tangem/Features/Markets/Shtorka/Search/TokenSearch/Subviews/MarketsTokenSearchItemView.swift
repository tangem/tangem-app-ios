//
//  MarketsTokenSearchItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MarketsTokenSearchItemView: View {
    @ScaledMetric private var tokensSpacing: CGFloat = .unit(.x2)
    @ScaledMetric private var retrySpacing: CGFloat = .unit(.x2)

    private let retryTopPadding: CGFloat = .unit(.x10)
    private let tokenBackgroundCornerRadius: CGFloat = .unit(.x5)

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
                with: .Tangem.Surface.level3,
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
                        with: .Tangem.Surface.level3,
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
