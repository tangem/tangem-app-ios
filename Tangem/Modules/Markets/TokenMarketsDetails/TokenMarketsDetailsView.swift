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

    @Environment(\.colorScheme) private var colorScheme

    @State private var descriptionBottomSheetHeight: CGFloat = 0
    @State private var isNavigationBarShadowLineViewVisible = false

    private var navigationBarBackgroundColor: Color {
        return colorScheme == .dark ? Colors.Background.primary : Colors.Background.secondary
    }

    private let scrollViewFrameCoordinateSpaceName = UUID()

    var body: some View {
        VStack(spacing: 0.0) {
            navigationBar

            scrollView
        }
        .navigationBarTitleDisplayMode(.inline)
        .if(!viewModel.isMarketsSheetStyle, transform: { view in
            view.navigationTitle(viewModel.tokenName)
        })
        .onOverlayContentStateChange { [weak viewModel] state in
            viewModel?.onOverlayContentStateChange(state)
        }
    }

    @ViewBuilder
    private var navigationBar: some View {
        if viewModel.isMarketsSheetStyle {
            NavigationBar(
                title: viewModel.tokenName,
                settings: .init(
                    titleColor: Colors.Text.primary1,
                    backgroundColor: navigationBarBackgroundColor,
                    height: 64.0,
                    alignment: .bottom
                ),
                leftItems: {
                    BackButton(height: 44.0, isVisible: true, isEnabled: true, action: viewModel.onBackButtonTap)
                },
                rightItems: {}
            )
            .overlay(alignment: .bottom) {
                Separator(height: .minimal, color: Colors.Stroke.primary)
                    .hidden(!isNavigationBarShadowLineViewVisible)
            }
        }
    }

    @ViewBuilder
    private var scrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .center, spacing: 16) {
                Group {
                    header

                    picker
                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 16.0)

                chart
                    .hidden(viewModel.allDataLoadFailed)
                    .overlay(content: {
                        MarketsUnableToLoadDataView(
                            isButtonBusy: viewModel.isLoading,
                            retryButtonAction: viewModel.loadDetailedInfo
                        )
                        .infinityFrame(axis: .horizontal)
                        .hidden(!viewModel.allDataLoadFailed)
                    })

                content
                    .hidden(viewModel.allDataLoadFailed)
                    .padding(.horizontal, 16.0)
                    .transition(.opacity)
            }
            .modifier(MarketsContentHidingViewModifier(initialProgress: viewModel.contentHidingInitialProgress))
            .padding(.top, Constants.scrollViewContentTopInset)
            .if(viewModel.isMarketsSheetStyle, transform: { view in
                view
                    .readContentOffset(inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName)) { contentOffset in
                        isNavigationBarShadowLineViewVisible = contentOffset.y > Constants.scrollViewContentTopInset
                    }
            })
        }
        .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
        .background(Colors.Background.tertiary.ignoresSafeArea())
        .bindAlert($viewModel.alert)
        .descriptionBottomSheet(
            info: $viewModel.descriptionBottomSheetInfo,
            sheetHeight: $descriptionBottomSheetHeight,
            backgroundColor: Colors.Background.action
        )
        .onChange(of: viewModel.descriptionBottomSheetInfo) { value in
            if value == nil {
                descriptionBottomSheetHeight = 0
            }
        }
        .animation(.default, value: viewModel.state)
        .animation(.default, value: viewModel.isLoading)
        .animation(.default, value: viewModel.allDataLoadFailed)
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                if let price = viewModel.price {
                    Text(price)
                        .blinkForegroundColor(
                            publisher: viewModel.$priceChangeAnimation,
                            positiveColor: Colors.Text.accent,
                            negativeColor: Colors.Text.warning,
                            originalColor: Colors.Text.primary1
                        )
                        .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(viewModel.priceDate)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    if let priceChangeState = viewModel.priceChangeState {
                        TokenPriceChangeView(state: priceChangeState, showSkeletonWhenLoading: true)
                    }
                }
            }

            Spacer(minLength: 8)

            IconView(url: viewModel.iconURL, size: .init(bothDimensions: 48), forceKingfisher: true)
        }
    }

    @ViewBuilder
    private var picker: some View {
        MarketsPickerView(
            marketPriceIntervalType: $viewModel.selectedPriceChangeIntervalType,
            options: viewModel.priceChangeIntervalOptions,
            shouldStretchToFill: true,
            style: .init(textVerticalPadding: 4),
            titleFactory: { $0.tokenDetailsNameLocalized }
        )
    }

    @ViewBuilder
    private var chart: some View {
        if let viewModel = viewModel.historyChartViewModel {
            MarketsHistoryChartView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 14) {
            switch viewModel.state {
            case .loading:
                ContentBlockSkeletons()
            case .loaded(let model):
                description(shortDescription: model.shortDescription, fullDescription: model.fullDescription)
                    .frame(maxWidth: .infinity, alignment: .leading)

                portfolioView

                contentBlocks
            case .failedToLoadDetails:
                MarketsUnableToLoadDataView(
                    isButtonBusy: viewModel.isLoading,
                    retryButtonAction: viewModel.loadDetailedInfo
                )
                .padding(.vertical, 6)
            case .failedToLoadAllData:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var portfolioView: some View {
        if let portfolioViewModel = viewModel.portfolioViewModel {
            MarketsPortfolioContainerView(viewModel: portfolioViewModel)
        }
    }

    @ViewBuilder
    private var contentBlocks: some View {
        VStack(spacing: 14) {
            if let insightsViewModel = viewModel.insightsViewModel {
                MarketsTokenDetailsInsightsView(viewModel: insightsViewModel)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
            }

            if let metricsViewModel = viewModel.metricsViewModel {
                MarketsTokenDetailsMetricsView(viewModel: metricsViewModel)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
            }

            if let pricePerformanceViewModel = viewModel.pricePerformanceViewModel {
                MarketsTokenDetailsPricePerformanceView(viewModel: pricePerformanceViewModel)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
            }

            if !viewModel.linksSections.isEmpty {
                TokenMarketsDetailsLinksView(sections: viewModel.linksSections)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
            }
        }
        .padding(.bottom, 46.0)
    }

    @ViewBuilder
    private func description(shortDescription: String?, fullDescription: String?) -> some View {
        if let shortDescription {
            if fullDescription == nil {
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
    }

    private var readMoreText: Text {
        let readMoreText = Localization.commonReadMore.replacingOccurrences(of: " ", with: AppConstants.unbreakableSpace)
        return Text(readMoreText).foregroundColor(Colors.Text.accent)
    }
}

// MARK: - Constants

private extension TokenMarketsDetailsView {
    enum Constants {
        static let chartHeight: CGFloat = 200.0
        static let scrollViewContentTopInset = 14.0
    }
}

// MARK: - Previews

#Preview {
    let tokenInfo = MarketsTokenModel(
        id: "bitcoin",
        name: "Bitcoin",
        symbol: "BTC",
        currentPrice: nil,
        priceChangePercentage: [:],
        marketRating: 1,
        marketCap: 100_000_000_000
    )

    return TokenMarketsDetailsView(viewModel: .init(tokenInfo: tokenInfo, style: .marketsSheet, dataProvider: .init(), marketsQuotesUpdateHelper: CommonMarketsQuotesUpdateHelper(), coordinator: nil))
}
