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
    @Environment(\.mainWindowSize) private var mainWindowSize

    @State private var headerHeight: CGFloat = .zero
    @State private var isListContentObscured = false

    private var isDarkColorScheme: Bool { colorScheme == .dark }
    private var defaultBackgroundColor: Color { isDarkColorScheme ? Colors.Background.primary : Colors.Background.secondary }
    private var overlayContentHidingBackgroundColor: Color { isDarkColorScheme ? defaultBackgroundColor : Colors.Background.plain }

    private let scrollViewFrameCoordinateSpaceName = UUID()

    var body: some View {
        rootView
            .if(!viewModel.isMarketsSheetStyle) { view in
                view.navigationTitle(viewModel.tokenName)
            }
            .onOverlayContentStateChange { [weak viewModel] state in
                viewModel?.onOverlayContentStateChange(state)
            }
            .onOverlayContentProgressChange { [weak viewModel] progress in
                viewModel?.onOverlayContentProgressChange(progress)
            }
            .background {
                viewBackground
            }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            scrollView

            navigationBar
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var navigationBar: some View {
        MarketsNavigationBar(
            isMarketsSheetStyle: viewModel.isMarketsSheetStyle,
            title: viewModel.tokenName,
            onBackButtonAction: viewModel.onBackButtonTap
        )
        .background(
            MarketsNavigationBarBackgroundView(
                backdropViewColor: overlayContentHidingBackgroundColor,
                overlayContentHidingProgress: viewModel.overlayContentHidingProgress,
                isNavigationBarBackgroundBackdropViewHidden: viewModel.isNavigationBarBackgroundBackdropViewHidden,
                isListContentObscured: isListContentObscured
            )
        )
        .readGeometry(\.size.height, bindTo: $headerHeight)
        .infinityFrame(axis: .vertical, alignment: .top)
    }

    @ViewBuilder
    private var scrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .center, spacing: 16) {
                // Using plain old overlay + dummy `Color.clear` spacer in the scroll view due to the buggy
                // `safeAreaInset(edge:alignment:spacing:content:)` iOS 15+ API which has both layout and touch-handling issues
                Color.clear
                    .frame(height: headerHeight)

                Group {
                    header

                    picker
                        .padding(.vertical, 8)
                        .disabled(viewModel.isLoading)
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
                    .padding(.horizontal, Constants.blockHorizontalPadding)
                    .transition(.opacity)
            }
            .padding(.top, Constants.scrollViewContentTopInset)
            .if(viewModel.isMarketsSheetStyle) { view in
                view
                    .readContentOffset(inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName)) { contentOffset in
                        isListContentObscured = contentOffset.y > Constants.scrollViewContentTopInset
                    }
            }
        }
        .opacity(viewModel.overlayContentHidingProgress)
        .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
        .bindAlert($viewModel.alert)
        .tokenDescriptionBottomSheet(
            info: $viewModel.descriptionBottomSheetInfo,
            backgroundColor: Colors.Background.action,
            onGeneratedAITapAction: viewModel.onGenerateAITapAction
        )
        .animation(.default, value: viewModel.state)
        .animation(.default, value: viewModel.isLoading)
        .animation(.default, value: viewModel.allDataLoadFailed)
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                if let price = viewModel.price {
                    // This `Text` view acts as an invisible container, maintaining constant height
                    // to prevent UI from jumping when the font of the price label is scaled down
                    Text(Constants.priceLabelSizeMeasureText)
                        .opacity(0.0)
                        .infinityFrame(axis: .horizontal)
                        .overlay(alignment: .leadingFirstTextBaseline) {
                            Text(price)
                                .blinkForegroundColor(
                                    publisher: viewModel.$priceChangeAnimation,
                                    positiveColor: Colors.Text.accent,
                                    negativeColor: Colors.Text.warning,
                                    originalColor: Colors.Text.primary1
                                )
                                .minimumScaleFactor(0.5)
                        }
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(viewModel.priceDate)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    if let priceChangeState = viewModel.priceChangeState {
                        TokenPriceChangeView(state: priceChangeState, showSkeletonWhenLoading: true)
                    }
                }
                .id(UUID())
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
            isDisabled: viewModel.isLoading && !viewModel.allDataLoadFailed,
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
            description
                .frame(maxWidth: .infinity, alignment: .leading)

            portfolioView

            switch viewModel.state {
            case .loading:
                ContentBlockSkeletons()
            case .loaded:
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
            let blocksWidth = mainWindowSize.width - Constants.blockHorizontalPadding * 2
            if let insightsViewModel = viewModel.insightsViewModel {
                MarketsTokenDetailsInsightsView(viewModel: insightsViewModel, viewWidth: blocksWidth)
            }

            if let metricsViewModel = viewModel.metricsViewModel {
                MarketsTokenDetailsMetricsView(viewModel: metricsViewModel, viewWidth: blocksWidth)
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
                TokenMarketsDetailsLinksView(viewWidth: blocksWidth, sections: viewModel.linksSections)
            }
        }
        .padding(.bottom, 46.0)
    }

    @ViewBuilder
    private var description: some View {
        switch viewModel.state {
        case .loading:
            DescriptionBlockSkeletons()
        case .loaded(let model):
            if let shortDescription = model.shortDescription {
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

    @ViewBuilder
    private var viewBackground: some View {
        ZStack {
            Group {
                // When a light color scheme is active, `defaultBackgroundColor` and `overlayContentHidingBackgroundColor`
                // colors simulate color blending with the help of dynamic opacity.
                //
                // When the dark color scheme is active, no color blending is needed, and only `defaultBackgroundColor`
                // is visible (btw in dark mode both colors are the same),
                defaultBackgroundColor
                    .opacity(isDarkColorScheme ? 1.0 : viewModel.overlayContentHidingProgress)

                overlayContentHidingBackgroundColor
                    .opacity(isDarkColorScheme ? 0.0 : 1.0 - viewModel.overlayContentHidingProgress)
            }
            .ignoresSafeArea()
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
        static let blockHorizontalPadding: CGFloat = 16.0
        static let priceLabelSizeMeasureText = "1234.0"
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
        marketCap: 100_000_000_000,
        isUnderMarketCapLimit: false
    )

    return TokenMarketsDetailsView(viewModel: .init(
        tokenInfo: tokenInfo,
        presentationStyle: .marketsSheet,
        dataProvider: .init(),
        marketsQuotesUpdateHelper: CommonMarketsQuotesUpdateHelper(),
        coordinator: nil
    ))
}
