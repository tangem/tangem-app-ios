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

            Group {
                if isLoading {
                    loadingSkeletons
                } else {
                    loadedTokens(tokens)
                }
            }
            .background(Colors.Background.action)
            .cornerRadiusContinuous(Constants.cornerRadius)
        }
    }

    private func sectionHeader(title: String, showCount: Bool, count: Int) -> some View {
        HStack(spacing: Constants.titleCountSpacing) {
            Text(title)
                .style(Fonts.BoldStatic.title3, color: Colors.Text.primary1)

            if showCount, count > 0 {
                Text("\(count)")
                    .style(Fonts.BoldStatic.title3, color: Colors.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.headerHorizontalPadding)
        .padding(.top, Constants.headerTopPadding)
        .padding(.bottom, Constants.headerBottomPadding)
    }

    private func loadedTokens(_ tokens: [MarketTokenItemViewModel]) -> some View {
        VStack(spacing: 0) {
            ForEach(tokens) { item in
                MarketTokenItemView(viewModel: item, cellWidth: mainWindowSize.width)
            }
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
        static let headerHorizontalPadding: CGFloat = 8
        static let headerTopPadding: CGFloat = 8
        static let headerBottomPadding: CGFloat = 14
        static let titleCountSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 14
        static let skeletonItemsCount: Int = 7
    }
}
