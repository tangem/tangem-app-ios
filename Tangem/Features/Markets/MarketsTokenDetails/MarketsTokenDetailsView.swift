//
//  MarketsTokenDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketsTokenDetailsView: View {
    @ObservedObject var viewModel: MarketsTokenDetailsViewModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.mainWindowSize) private var mainWindowSize

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    @State private var headerHeight: CGFloat = .zero
    @State private var isListContentObscured = false

    @StateObject private var scrollOffsetHandler = ScrollViewOffsetHandler.marketTokenDetails(
        initialState: MarketsNavigationBarTitle.State(priceOpacity: nil, titleOffset: 0),
        labelOffset: Constants.scrollViewContentTopInset + Constants.scrollViewVerticalPadding
    )

    private var isDarkColorScheme: Bool { colorScheme == .dark }

    /// `UIColor` is used since `Color(uiColor:)` constructor loses Xcode color asset dark/light appearance setting.
    @available(iOS, deprecated: 18.0, message: "Replace 'UIColor' with 'Color' since 'Color.mix(with:by:in:)' is available")
    private var defaultBackgroundColor: UIColor {
        isDarkColorScheme ? UIColor.backgroundPrimary.forcedDark : UIColor.backgroundSecondary.forcedLight
    }

    /// `UIColor` is used since `Color(uiColor:)` constructor loses Xcode color asset dark/light appearance setting.
    @available(iOS, deprecated: 18.0, message: "Replace 'UIColor' with 'Color' since 'Color.mix(with:by:in:)' is available")
    private var overlayContentHidingBackgroundColor: UIColor {
        isDarkColorScheme ? defaultBackgroundColor.forcedDark : UIColor.backgroundPlain.forcedLight
    }

    private let scrollViewFrameCoordinateSpaceName = UUID()

    var body: some View {
        rootViewWithTitle
            .onOverlayContentStateChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] state in
                viewModel?.onOverlayContentStateChange(state)
            }
            .onOverlayContentProgressChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] progress in
                viewModel?.onOverlayContentProgressChange(progress)
            }
            .background {
                backgroundColor
                    .ignoresSafeArea(edges: .vertical)
            }
            .onAppear(perform: scrollOffsetHandler.onViewAppear)
    }

    @ViewBuilder
    private var rootViewWithTitle: some View {
        if !viewModel.isMarketsSheetStyle {
            rootView
                .toolbar(content: {
                    ToolbarItem(placement: .principal) {
                        navigationBarTitle
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: viewModel.shareTokenDetails) {
                            Assets.Glyphs.moreVertical.image
                        }
                    }
                })
        } else {
            rootView
        }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            scrollView

            if viewModel.isMarketsSheetStyle {
                navigationBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var navigationBar: some View {
        MarketsNavigationBar(
            titleView: { navigationBarTitle },
            onBackButtonAction: viewModel.onBackButtonTap,
            rightButtons: {
                Button(action: viewModel.shareTokenDetails) {
                    Assets.Glyphs.moreVertical.image
                        .padding(.trailing, 16)
                }
            }
        )
        .background(
            MarketsNavigationBarBackgroundView(
                backdropViewColor: backgroundColor,
                overlayContentHidingProgress: viewModel.overlayContentHidingProgress,
                isNavigationBarBackgroundBackdropViewHidden: viewModel.isNavigationBarBackgroundBackdropViewHidden,
                isListContentObscured: isListContentObscured
            )
        )
        .readGeometry(\.size.height, bindTo: $headerHeight)
        .infinityFrame(axis: .vertical, alignment: .top)
    }

    private var navigationBarTitle: some View {
        MarketsNavigationBarTitle(
            tokenName: viewModel.tokenName,
            price: viewModel.price,
            state: viewModel.overlayContentHidingProgress > 0
                ? scrollOffsetHandler.state
                : MarketsNavigationBarTitle.State(
                    priceOpacity: 1,
                    titleOffset: ScrollViewOffsetHandler.MarketsTokenDetailsConstants.maxTitleOffset
                )
        )
    }

    @ViewBuilder
    private var scrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .center, spacing: Constants.scrollViewVerticalPadding) {
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
                        UnableToLoadDataView(
                            isButtonBusy: viewModel.isLoading,
                            retryButtonAction: viewModel.loadDetailedInfo
                        )
                        .infinityFrame(axis: .horizontal)
                        .hidden(!viewModel.allDataLoadFailed)
                    })

                content
                    .hidden(viewModel.allDataLoadFailed)
                    .transition(.opacity)
            }
            .padding(.top, Constants.scrollViewContentTopInset)
            .readContentOffset(inCoordinateSpace: .named(scrollViewFrameCoordinateSpaceName)) { contentOffset in
                scrollOffsetHandler.contentOffsetSubject.send(contentOffset)
                if viewModel.isMarketsSheetStyle {
                    isListContentObscured = contentOffset.y > Constants.scrollViewContentTopInset
                }
            }
        }
        .opacity(viewModel.overlayContentHidingProgress)
        .coordinateSpace(name: scrollViewFrameCoordinateSpaceName)
        .bindAlert($viewModel.alert)
        .if(!viewModel.isRedesignEnabled) { view in
            view
                .descriptionBottomSheet(
                    info: $viewModel.descriptionBottomSheetInfo,
                    backgroundColor: Colors.Background.action
                )
                .tokenDescriptionBottomSheet(
                    info: $viewModel.fullDescriptionBottomSheetInfo,
                    backgroundColor: Colors.Background.action,
                    onGeneratedAITapAction: viewModel.onGenerateAITapAction
                )
        }
        .sheet(item: $viewModel.securityScoreDetailsViewModel) { viewModel in
            MarketsTokenDetailsSecurityScoreDetailsView(viewModel: viewModel)
                .adaptivePresentationDetents()
                .background(Colors.Background.tertiary.ignoresSafeArea())
        }
        .animation(.default, value: viewModel.state)
        .animation(.default, value: viewModel.isLoading)
        .animation(.default, value: viewModel.allDataLoadFailed)
    }

    @ViewBuilder
    private var header: some View {
        if viewModel.isRedesignEnabled {
            headerRedesign
        } else {
            headerLegacy
        }
    }

    private var headerRedesign: some View {
        MarketsTokenDetailsHeaderView(
            tokenName: viewModel.tokenName,
            tokenSymbol: viewModel.tokenSymbol,
            price: viewModel.attributedPrice,
            priceDate: viewModel.priceDate,
            priceChangeState: viewModel.priceChangeState,
            priceChangeAnimation: viewModel.$priceChangeAnimation,
            iconURL: viewModel.iconURL
        )
    }

    private var headerLegacy: some View {
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
                        PriceChangeView(state: priceChangeState, showSkeletonWhenLoading: true)
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
            style: .init(textVerticalPadding: 4),
            titleFactory: { $0.tokenDetailsNameLocalized }
        )
        .disabled(viewModel.isLoading && !viewModel.allDataLoadFailed)
    }

    @ViewBuilder
    private var chart: some View {
        if let viewModel = viewModel.historyChartViewModel {
            MarketsHistoryChartView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var content: some View {
        if FeatureProvider.isAvailable(.redesign) {
            MarketsTokenDetailsContentViewRedesign(viewModel: viewModel)
        } else {
            MarketsTokenDetailsContentView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var backgroundColor: Color {
        let uiColor = overlayContentHidingBackgroundColor.mix(
            with: defaultBackgroundColor,
            by: viewModel.overlayContentHidingProgress
        )

        Color(uiColor: uiColor)
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsView {
    enum Constants {
        static let chartHeight = 200.0
        static let scrollViewContentTopInset = 14.0
        static let scrollViewVerticalPadding = 16.0
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
        maxYieldApy: .zero,
        marketCap: 100_000_000_000,
        isUnderMarketCapLimit: false,
        stakingOpportunities: nil,
        networks: nil,
    )

    return MarketsTokenDetailsView(viewModel: .init(
        tokenInfo: tokenInfo,
        presentationStyle: .marketsSheet,
        dataProvider: .init(),
        marketsQuotesUpdateHelper: CommonMarketsQuotesUpdateHelper(),
        coordinator: nil
    ))
}
