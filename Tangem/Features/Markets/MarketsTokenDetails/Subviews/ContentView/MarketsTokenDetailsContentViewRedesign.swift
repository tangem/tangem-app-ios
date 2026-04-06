//
//  MarketsTokenDetailsContentViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct MarketsTokenDetailsContentViewRedesign: View {
    @ObservedObject var viewModel: MarketsTokenDetailsViewModel

    @Environment(\.mainWindowSize) private var mainWindowSize

    private var shortDescription: String? {
        guard case .loaded(let model) = viewModel.state else {
            return nil
        }

        return model.shortDescription
    }

    private var blocksWidth: CGFloat {
        mainWindowSize.width - Constants.contentHorizontalPadding * 2
    }

    var body: some View {
        VStack(spacing: Constants.contentVerticalSpacing) {
            let hasShortDescription = viewModel.descriptionCanBeShowed && shortDescription != nil

            if hasShortDescription {
                description
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Constants.contentHorizontalPadding)
            }

            portfolioView
                .padding(.horizontal, Constants.contentHorizontalPadding)
                .padding(.top, hasShortDescription ? 0 : Constants.contentVerticalSpacing)

            newsView

            coinView
        }
    }

    @ViewBuilder
    private var portfolioView: some View {
        if let portfolioViewModel = viewModel.portfolioViewModel {
            MarketsPortfolioContainerView(viewModel: portfolioViewModel)
        }
    }

    @ViewBuilder
    private var newsView: some View {
        if viewModel.isAvailableNews {
            MarketsTokenNewsView(
                items: viewModel.tokenNewsItems,
                onFourthItemAppear: viewModel.logCarouselScrolledIfNeeded
            )
        }
    }

    private var coinView: some View {
        VStack(spacing: Constants.coinVerticalPadding) {
            if viewModel.portfolioViewModel != nil {
                aboutCoinHeader
            }

            switch viewModel.state {
            case .loading:
                MarketsTokenDetailsView.ContentBlockSkeletons()
            case .loaded:
                contentBlocks
            case .failedToLoadDetails:
                UnableToLoadDataView(
                    isButtonBusy: viewModel.isLoading,
                    retryButtonAction: viewModel.loadDetailedInfo
                )
                .padding(.vertical, 6)
            case .failedToLoadAllData:
                EmptyView()
            }
        }
        .padding(.horizontal, Constants.contentHorizontalPadding)
    }

    private var aboutCoinHeader: some View {
        Text(Localization.marketsAboutCoinHeader)
            .style(Fonts.Bold.title3, color: Colors.Text.primary1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8.0)
    }

    @ViewBuilder
    private var contentBlocks: some View {
        VStack(spacing: Constants.coinVerticalPadding) {
            if let metricsViewModel = viewModel.metricsViewModel {
                MarketsTokenDetailsMetricsView(viewModel: metricsViewModel, viewWidth: blocksWidth)
            }

            if let insightsViewModel = viewModel.insightsViewModel {
                MarketsTokenDetailsInsightsView(viewModel: insightsViewModel, viewWidth: blocksWidth)
            }

            if let securityScoreViewModel = viewModel.securityScoreViewModel {
                MarketsTokenDetailsSecurityScoreView(viewModel: securityScoreViewModel)
            }

            if let pricePerformanceViewModel = viewModel.pricePerformanceViewModel {
                MarketsTokenDetailsPricePerformanceView(viewModel: pricePerformanceViewModel)
            }

            if let numberOfExchangesListedOn = viewModel.numberOfExchangesListedOn {
                MarketsTokenDetailsListedOnExchangesView(exchangesCount: numberOfExchangesListedOn) {
                    viewModel.openExchangesList()
                }
            }

            if !viewModel.linksSections.isEmpty {
                MarketsTokenDetailsLinksView(viewWidth: blocksWidth, sections: viewModel.linksSections)
            }
        }
        .padding(.bottom, 46.0)
    }

    @ViewBuilder
    private var description: some View {
        switch viewModel.state {
        case .loading:
            MarketsTokenDetailsView.DescriptionBlockSkeletons()
        case .loaded(let model):
            if let shortDescription {
                if model.fullDescription == nil {
                    Text(shortDescription)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                        .multilineTextAlignment(.leading)
                } else {
                    Button(action: viewModel.openFullDescription) {
                        Group {
                            Text("\(shortDescription) ")
                                + readMoreText
                        }
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                        .multilineTextAlignment(.leading)
                    }
                }
            }
        case .failedToLoadDetails, .failedToLoadAllData:
            EmptyView()
        }
    }

    private var readMoreText: Text {
        let readMoreText = Localization.commonReadMore.replacingOccurrences(of: " ", with: String.unbreakableSpace)
        return Text(readMoreText).foregroundColor(Colors.Text.accent)
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsContentViewRedesign {
    enum Constants {
        static let contentVerticalSpacing: CGFloat = 32
        static let contentHorizontalPadding: CGFloat = 16
        static let coinVerticalPadding: CGFloat = 14
    }
}
