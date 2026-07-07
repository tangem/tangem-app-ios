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

            marketingBanner

            content
        }
    }

    @ViewBuilder
    private var marketingBanner: some View {
        if let marketingNotifications = viewModel.marketingNotifications {
            NotificationBannerContainer(
                items: marketingNotifications,
                stackingType: .carousel
            )
            .padding(.horizontal, Constants.contentHorizontalPadding)
        }
    }

    private var content: some View {
        VStack(spacing: Constants.coinVerticalPadding) {
            switch viewModel.state {
            case .loading:
                MarketsTokenDetailsView.ContentBlockSkeletonsRedesign()
                    .padding(.horizontal, Constants.contentHorizontalPadding)

            case .loaded:
                contentBlocks

            case .failedToLoadDetails:
                TangemUnableToLoadDataView(
                    isButtonBusy: viewModel.isLoading,
                    retryButtonAction: viewModel.loadDetailedInfo
                )
                .padding(.top, .unit(.x17))
                .padding(.horizontal, Constants.contentHorizontalPadding)

            case .failedToLoadAllData:
                EmptyView()
            }
        }
    }

    private var contentBlocks: some View {
        VStack(spacing: Constants.coinVerticalPadding) {
            if let metricsViewModel = viewModel.metricsViewModel {
                MarketsTokenDetailsMetricsViewRedesign(viewModel: metricsViewModel)
                    .padding(.horizontal, Constants.contentHorizontalPadding)
            }

            if let insightsViewModel = viewModel.insightsViewModel {
                MarketsTokenDetailsInsightsViewRedesign(viewModel: insightsViewModel)
                    .padding(.horizontal, Constants.contentHorizontalPadding)
            }

            if let numberOfExchangesListedOn = viewModel.numberOfExchangesListedOn {
                MarketsTokenDetailsListedOnExchangesViewRedesign(exchangesCount: numberOfExchangesListedOn) {
                    viewModel.openExchangesList()
                }
                .padding(.horizontal, Constants.contentHorizontalPadding)
            }

            if let securityScoreViewModel = viewModel.securityScoreViewModel {
                MarketsTokenDetailsSecurityScoreViewRedesign(viewModel: securityScoreViewModel)
                    .padding(.horizontal, Constants.contentHorizontalPadding)
            }

            newsView

            if viewModel.linksSections.isNotEmpty {
                MarketsTokenDetailsLinksViewRedesign(sections: viewModel.linksSections)
                    .padding(.horizontal, Constants.contentHorizontalPadding)
            }
        }
        .padding(.bottom, 46.0)
    }

    @ViewBuilder
    private var description: some View {
        switch viewModel.state {
        case .loading:
            MarketsTokenDetailsView.DescriptionBlockSkeletonsRedesign()

        case .loaded(let model):
            if let shortDescription {
                if model.fullDescription == nil {
                    Text(shortDescription)
                        .style(Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.tertiary)
                        .multilineTextAlignment(.leading)
                } else {
                    Button(action: viewModel.openFullDescription) {
                        Group {
                            Text("\(shortDescription) ")
                                + readMoreText
                        }
                        .style(Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.tertiary)
                        .multilineTextAlignment(.leading)
                    }
                }
            }

        case .failedToLoadDetails, .failedToLoadAllData:
            EmptyView()
        }
    }

    @ViewBuilder
    private var newsView: some View {
        if viewModel.isAvailableNews {
            MarketsTokenNewsView(
                items: viewModel.tokenNewsItems,
                onFourthItemAppear: viewModel.logCarouselScrolledIfNeeded
            )
            .padding(.top, Constants.newsExtraTopPadding)
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
        static let contentHorizontalPadding: CGFloat = .unit(.x4)
        static let coinVerticalPadding: CGFloat = .unit(.x3)
        static let newsExtraTopPadding: CGFloat = .unit(.x5)
    }
}
