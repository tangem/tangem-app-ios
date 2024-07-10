//
//  TokenMarketsDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenMarketsDetailsView: View {
    @ObservedObject var viewModel: TokenMarketsDetailsViewModel

    var body: some View {
        VStack(spacing: 0) {
            SheetHandleView(backgroundColor: Colors.Background.tertiary)

            NavigationView {
                content
            }
        }
        .background(Colors.Background.tertiary)
    }

    var content: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                header

                MarketsPickerView(
                    marketPriceIntervalType: $viewModel.selectedPriceChangeIntervalType,
                    options: viewModel.priceChangeIntervalOptions,
                    shouldStretchToFill: true,
                    titleFactory: { $0.rawValue.capitalizingFirstLetter() }
                )
                .padding(.horizontal, 16)

                chart

                description

                contentBlocks
                    .padding(.bottom, 45)
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text(viewModel.tokenName))
        .background(Colors.Background.tertiary)
        .bindAlert($viewModel.alert)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.price)
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(viewModel.priceDate)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    TokenPriceChangeView(state: viewModel.priceChangeState, showSkeletonWhenLoading: true)
                }
            }

            Spacer(minLength: 8)

            IconView(url: viewModel.iconURL, size: .init(bothDimensions: 48), forceKingfisher: true)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var description: some View {
        if let shortDescription = viewModel.shortDescription {
            Group {
                if viewModel.fullDescription == nil {
                    Text(shortDescription)
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                        .multilineTextAlignment(.leading)
                } else {
                    Button(action: viewModel.openFullDescription) {
                        Group {
                            Text("\(shortDescription) ")
                                + Text(Localization.commonReadMore)
                                .foregroundColor(Colors.Text.accent)
                        }
                        .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                        .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var chart: some View {
        // [REDACTED_TODO_COMMENT]
        Image(systemName: "chart.xyaxis.line")
            .style(Font.system(size: 80), color: Colors.Icon.accent)
    }

    private var contentBlocks: some View {
        VStack(spacing: 14) {
            MarketsEmptyAddTokenView(didTapAction: viewModel.onAddToPortfolioTapAction)
                .padding(.horizontal, 16)

            if viewModel.isLoading {
                ContentBlockSkeletons()
            } else {
                Group {
                    if let insightsViewModel = viewModel.insightsViewModel {
                        MarketsTokenDetailsInsightsView(viewModel: insightsViewModel)
                            .animation(nil, value: viewModel.isLoading)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .animation(.default, value: viewModel.isLoading)
    }
}

#Preview {
    let tokenInfo = MarketsTokenModel(
        id: "bitcoint",
        name: "Bitcoin",
        symbol: "BTC",
        currentPrice: nil,
        priceChangePercentage: [:],
        marketRating: 1,
        marketCap: 100_000_000_000
    )

    return TokenMarketsDetailsView(viewModel: .init(tokenInfo: tokenInfo, dataProvider: .init(), coordinator: nil))
}
