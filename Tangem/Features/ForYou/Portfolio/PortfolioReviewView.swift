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
                skeletonList
            case .content(let content):
                ForYouPeriodPickerView(
                    segments: content.periodSegments,
                    selection: $viewModel.selectedPeriod
                )
                tokenList(content.tokenList)
            }
        }
    }
}

private extension PortfolioReviewView {
    var periodPickerShimmer: some View {
        TangemShimmer()
            .variant(.custom(height: 40, cornerRadius: 20))
            .frame(maxWidth: .infinity)
    }

    var skeletonList: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 4, id: \.self) { _ in
                PortfolioTokenSkeletonRow()
            }
        }
    }

    func tokenList(_ items: [ForYouTokenListItem]) -> some View {
        VStack(spacing: 8) {
            ForEach(items) { item in
                PortfolioTokenItemView(item: item, onAssetTap: viewModel.toggle)
            }
        }
    }
}
