//
//  CryptoSearchView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI

struct CryptoSearchView<Header: View>: View {
    @ObservedObject var viewModel: CryptoSearchViewModel

    private let header: Header

    init(
        viewModel: CryptoSearchViewModel,
        @ViewBuilder header: () -> Header = { EmptyView() }
    ) {
        self.viewModel = viewModel
        self.header = header()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                    header
                    if let portfolio = viewModel.portfolio {
                        FeedSearchSection(title: Localization.marketsCommonMyPortfolio) {
                            CryptoSearchPortfolioView(viewModel: portfolio)
                                .padding(.horizontal, Constants.horizontalPadding)
                        }
                    }

                    marketsSection
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

private extension CryptoSearchView {
    @ViewBuilder
    var marketsSection: some View {
        switch viewModel.markets {
        case .loading:
            FeedSearchSkeletonView()

        case .results(let rows, let hasTokensUnderCap):
            FeedSearchSection(title: Localization.marketsCommonTitle) {
                CryptoSearchResultsView(
                    rows: rows,
                    onAppear: viewModel.onResultAppear,
                    onDisappear: viewModel.onResultDisappear
                )

                if hasTokensUnderCap {
                    tokensUnderCapNotice
                }
            }

        case .empty:
            FeedSearchEmptyView(title: Localization.commonNoResults)
                .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSearchNoResultsLabel)

        case .failed:
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.onRetry)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.errorVerticalInset)
        }
    }

    var tokensUnderCapNotice: some View {
        VStack(spacing: Constants.noticeSpacing) {
            Text(Localization.marketsSearchSeeTokensUnder100k)
                .multilineTextAlignment(.center)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

            TangemUI.Button(
                label: Localization.marketsSearchShowTokens,
                accessibilityLabel: Localization.marketsSearchShowTokens,
                action: viewModel.onShowTokensUnderCap
            )
            .styleType(.secondary(.default))
            .size(.x8)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsTokensUnderCapExpandButton)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Constants.noticeTopInset)
        .padding(.horizontal, Constants.noticeHorizontalInset)
    }
}

// MARK: - Constants

private enum Constants {
    static let contentID = "cryptoSearchContent"
    static let contentVerticalInset: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let horizontalPadding: CGFloat = 16
    static let errorVerticalInset: CGFloat = 24
    static let noticeSpacing: CGFloat = 8
    static let noticeTopInset: CGFloat = 24
    static let noticeHorizontalInset: CGFloat = 24
}
