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
    @ObservedObject var viewModel: AccountsAwareTokenSelectorViewModel

    let cellWidth: CGFloat

    var body: some View {
        if viewModel.isSearchingExternal || !viewModel.externalSearchResults.isEmpty {
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

            if !viewModel.externalSearchResults.isEmpty {
                Text("\(viewModel.externalSearchResults.count)")
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
        if viewModel.isSearchingExternal {
            loadingIndicator
                .background(Colors.Background.action)
                .cornerRadiusContinuous(Constants.cornerRadius)
        } else {
            VStack(spacing: 0) {
                ForEach(viewModel.externalSearchResults) { item in
                    MarketTokenItemView(viewModel: item, cellWidth: cellWidth)
                }
            }
            .background(Colors.Background.action)
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }

    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
            Spacer()
        }
        .padding(.vertical, Constants.loadingIndicatorVerticalPadding)
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
        static let loadingIndicatorVerticalPadding: CGFloat = 16
    }
}
