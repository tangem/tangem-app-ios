//
//  ExpressExternalTokensSection.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct ExpressExternalTokensSection: View {
    @ObservedObject var viewModel: ExpressExternalSearchViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .noResults:
                EmptyView()
            case .loading(let mode):
                sectionContent(title: mode.title, showCount: false, tokens: [], isLoading: true)
            case .loaded(let tokens, let mode):
                sectionContent(title: mode.title, showCount: mode.showsTokenCount, tokens: tokens, isLoading: false)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private func sectionContent(
        title: String,
        showCount: Bool,
        tokens: [MarketTokenItemViewModel],
        isLoading: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: title, showCount: showCount, count: tokens.count)

            if isLoading {
                loadingSkeletons
                    .background(Colors.Background.action)
                    .cornerRadiusContinuous(Constants.cornerRadius)
            } else {
                VStack(spacing: 0) {
                    ForEach(tokens) { item in
                        MarketTokenItemView(viewModel: item, cellWidth: mainWindowSize.width)
                    }
                }
                .background(Colors.Background.action)
                .cornerRadiusContinuous(Constants.cornerRadius)
            }
        }
    }

    private func sectionHeader(title: String, showCount: Bool, count: Int) -> some View {
        HStack(spacing: Constants.titleCountSpacing) {
            Text(title)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            if showCount, count > 0 {
                Text("\(count)")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.headerTopPadding)
        .padding(.bottom, Constants.headerBottomPadding)
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
