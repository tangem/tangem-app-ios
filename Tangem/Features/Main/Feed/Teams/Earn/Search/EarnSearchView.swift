//
//  EarnSearchView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct EarnSearchView: View {
    @ObservedObject var viewModel: EarnSearchViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                    if let portfolio = viewModel.portfolio {
                        FeedSearchSection(title: Localization.marketsCommonMyPortfolio) {
                            CryptoSearchPortfolioView(viewModel: portfolio)
                                .padding(.horizontal, Constants.horizontalPadding)
                        }
                    }

                    opportunitiesSection
                }
                .id(Constants.contentID)
                .padding(.vertical, Constants.contentVerticalInset)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.query) { _ in
                withTransaction(.withoutAnimations()) {
                    proxy.scrollTo(Constants.contentID, anchor: .top)
                }
            }
        }
    }
}

// MARK: - Subviews

private extension EarnSearchView {
    @ViewBuilder
    var opportunitiesSection: some View {
        switch viewModel.opportunities {
        case .loading:
            FeedSearchSkeletonView()

        case .results(let results):
            resultsSection(results)

        case .empty:
            FeedSearchEmptyView(title: Localization.commonNoResults)

        case .failed:
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.onRetry)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.errorVerticalInset)
        }
    }

    func resultsSection(_ results: [EarnTokenItemViewModel]) -> some View {
        FeedSearchSection(title: FeedTabKind.earn.title) {
            LazyVStack(spacing: 0) {
                ForEach(results) { result in
                    EarnTokenItemViewRedesign(viewModel: result)
                }
            }
        }
    }
}

// MARK: - Constants

private extension EarnSearchView {
    enum Constants {
        static let contentID = "earnSearchContent"
        static let contentVerticalInset: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
        static let errorVerticalInset: CGFloat = 24
    }
}
