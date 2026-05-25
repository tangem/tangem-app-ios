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
            }

            content
        }
        .padding(.horizontal, Constants.contentHorizontalPadding)
    }

    private var content: some View {
        VStack(spacing: Constants.coinVerticalPadding) {
            switch viewModel.state {
            case .loading:
                MarketsTokenDetailsView.ContentBlockSkeletonsRedesign()

            case .loaded:
                contentBlocks

            case .failedToLoadDetails:
                TangemUnableToLoadDataView(
                    isButtonBusy: viewModel.isLoading,
                    retryButtonAction: viewModel.loadDetailedInfo
                )
                .padding(.top, .unit(.x17))

            case .failedToLoadAllData:
                EmptyView()
            }
        }
    }

    private var contentBlocks: some View {
        VStack(spacing: Constants.coinVerticalPadding) {
            if let metricsViewModel = viewModel.metricsViewModel {
                MarketsTokenDetailsMetricsViewRedesign(viewModel: metricsViewModel)
            }

            if let insightsViewModel = viewModel.insightsViewModel {
                MarketsTokenDetailsInsightsViewRedesign(viewModel: insightsViewModel)
            }

            if let numberOfExchangesListedOn = viewModel.numberOfExchangesListedOn {
                MarketsTokenDetailsListedOnExchangesViewRedesign(exchangesCount: numberOfExchangesListedOn) {
                    viewModel.openExchangesList()
                }
            }

            newsView

            if let securityScoreViewModel = viewModel.securityScoreViewModel {
                MarketsTokenDetailsSecurityScoreViewRedesign(viewModel: securityScoreViewModel)
            }

            if viewModel.linksSections.isNotEmpty {
                MarketsTokenDetailsLinksViewRedesign(sections: viewModel.linksSections)
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
                        .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.secondary)
                        .multilineTextAlignment(.leading)
                } else {
                    Button(action: viewModel.openFullDescription) {
                        Group {
                            Text("\(shortDescription) ")
                                + readMoreText
                        }
                        .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.secondary)
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
        static let coinVerticalPadding: CGFloat = 14
    }
}
