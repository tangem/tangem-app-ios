//
//  PortfolioReviewView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct PortfolioReviewView: View {
    @ObservedObject var viewModel: PortfolioReviewViewModel

    var body: some View {
        VStack(spacing: 8) {
            ForYouPeriodPickerView(
                segments: viewModel.state.periodSegments,
                selection: $viewModel.selectedPeriod
            )
            tokenList(viewModel.state.tokenList)
        }
    }
}

private extension PortfolioReviewView {
    func tokenList(_ items: [ForYouTokenListItem]) -> some View {
        VStack(spacing: 8) {
            ForEach(items) { item in
                PortfolioTokenItemView(item: item, onAssetTap: viewModel.toggle)
            }
        }
    }
}
