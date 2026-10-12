//
//  RealAssetsSearchView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct RealAssetsSearchView: View {
    @ObservedObject var viewModel: RealAssetsSearchViewModel

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

                    assetsSection
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

private extension RealAssetsSearchView {
    @ViewBuilder
    var assetsSection: some View {
        switch viewModel.assets {
        case .loading:
            FeedSearchSkeletonView()

        case .results(let rows):
            FeedSearchSection(title: FeedTabKind.realAssets.title) {
                CryptoSearchResultsView(
                    rows: rows,
                    onAppear: viewModel.onResultAppear,
                    onDisappear: viewModel.onResultDisappear
                )
            }

        case .empty:
            FeedSearchEmptyView(title: Localization.commonNoResults)

        case .failed:
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.onRetry)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.errorVerticalInset)
        }
    }
}

// MARK: - Constants

private extension RealAssetsSearchView {
    enum Constants {
        static let contentID = "realAssetsSearchContent"
        static let contentVerticalInset: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
        static let errorVerticalInset: CGFloat = 24
    }
}
