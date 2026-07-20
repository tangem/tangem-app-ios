//
//  PortfolioReviewView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct PortfolioReviewView: View {
    @ObservedObject var viewModel: PortfolioReviewViewModel

    var body: some View {
        VStack(spacing: 8) {
            switch viewModel.state {
            case .loading:
                periodPickerShimmer
                    .transition(.opacity)
                skeletonList
                    .transition(.opacity)
            case .content(let content):
                ForYouPeriodPickerView(
                    segments: content.periodSegments,
                    selection: $viewModel.selectedPeriod
                )
                .transition(.opacity)
                tokenList(content.tokenList)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

private extension PortfolioReviewView {
    var isLoading: Bool {
        if case .loading = viewModel.state {
            return true
        }
        return false
    }

    var periodPickerShimmer: some View {
        TangemShimmer()
            .variant(.custom(height: 40, cornerRadius: 20))
            .frame(maxWidth: .infinity)
    }

    var skeletonList: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 4, id: \.self) { _ in
                TangemTwoLineRowSkeletonView()
                    .portfolioTokenCard()
            }
        }
    }

    func tokenList(_ items: [ForYouTokenListItem]) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(items) { item in
                PortfolioTokenItemView(item: item, onAssetTap: viewModel.toggle)
            }
        }
    }
}
