//
//  ExpressExternalTokensSection.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct ExpressExternalTokensSection: View {
    @ObservedObject var viewModel: ExpressExternalSearchViewModel

    let cellWidth: CGFloat

    var body: some View {
        if viewModel.isSearching || !viewModel.searchResults.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader

                tokensList
            }
        }
    }

    private var sectionHeader: some View {
        HStack(spacing: Constants.titleCountSpacing) {
            Text(Localization.commonFeeSelectorOptionMarket)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            if !viewModel.searchResults.isEmpty {
                Text("\(viewModel.searchResults.count)")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.headerTopPadding)
        .padding(.bottom, Constants.headerBottomPadding)
    }

    @ViewBuilder
    private var tokensList: some View {
        if viewModel.isSearching {
            loadingSkeletons
                .background(Colors.Background.action)
                .cornerRadiusContinuous(Constants.cornerRadius)
        } else {
            VStack(spacing: 0) {
                ForEach(viewModel.searchResults) { item in
                    MarketTokenItemView(viewModel: item, cellWidth: cellWidth)
                }
            }
            .background(Colors.Background.action)
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }

    private var loadingSkeletons: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< Constants.skeletonItemsCount, id: \.self) { _ in
                MarketsSkeletonItemView()
            }
        }
    }
}

// MARK: - Constants

extension ExpressExternalTokensSection {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let headerTopPadding: CGFloat = 14
        static let headerBottomPadding: CGFloat = 10
        static let titleCountSpacing: CGFloat = 4
        static let cornerRadius: CGFloat = 14
        static let skeletonItemsCount: Int = 7
    }
}
