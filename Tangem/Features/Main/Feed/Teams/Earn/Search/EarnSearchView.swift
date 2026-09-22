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
                opportunitiesSection
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
        VStack(alignment: .leading, spacing: Constants.sectionHeaderSpacing) {
            Text(Localization.feedTabEarn)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
                .padding(.horizontal, Constants.horizontalPadding)

            LazyVStack(spacing: 0) {
                ForEach(results) { result in
                    EarnTokenItemViewRedesign(viewModel: result)
                }
            }
            .roundedBackground(with: DesignSystem.Color.bgSecondary, padding: 0, radius: Constants.cornerRadius)
            .padding(.horizontal, Constants.horizontalPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Constants

private extension EarnSearchView {
    enum Constants {
        static let contentID = "earnSearchContent"
        static let contentVerticalInset: CGFloat = 8
        static let sectionHeaderSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 20
        static let horizontalPadding: CGFloat = 16
        static let errorVerticalInset: CGFloat = 24
    }
}
