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
        switch viewModel.presentationStyle {
        case .addFundsSheet:
            rootViewWithHiddenBackBarButton

        case .marketsSheet:
            rootView

        case .navigationStack:
            rootViewWithToolbar

        case .fullScreenCover:
            rootView
        }
    }

    private var rootViewWithHiddenBackBarButton: some View {
        rootView
            .navigationBarBackButtonHidden()
    }

    private var rootView: some View {
        ZStack {
            scrollView

            if viewModel.shouldShowPortfolioBlock {
                navigationBar
            }
        }
        .animation(.curve(.easeInOutRefined, duration: 0.5), value: viewModel.portfolioBlockState.isVisible)
        .animation(.curve(.easeInOutRefined, duration: 0.5), value: viewModel.isAddButtonVisible)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var navigationBar: some View {
        redesignedNavigationBar
    }

    // MARK: - Redesigned navigation

    private var redesignedNavigationBar: some View {
        NavigationHeader(
            leadingContent: { redesignedBackButton },
            principalContent: { EmptyView() },
            trailingContent: { redesignedTrailingButtons }
        )
        .readGeometry(\.size.height, bindTo: $headerHeight)
        .infinityFrame(axis: .vertical, alignment: .top)
    }

    private var redesignedBackButton: some View {
        NavigationBarButton.back(action: viewModel.onBackButtonTap)
            .redesigned()
    }

    @ViewBuilder
    private var redesignedTrailingButtons: some View {
        HStack(spacing: 12) {
            if let priceAlertBellViewModel = viewModel.priceAlertBellViewModel {
                PriceAlertBellView(viewModel: priceAlertBellViewModel)
            }

            if viewModel.isMarketsSheetStyle, viewModel.isAddButtonVisible {
                redesignedAddButton
            }

            redesignedShareButton
        }
    }

    private var redesignedAddButton: some View {
        NavigationBarButton.add(action: viewModel.onTapAddButton)
            .redesigned()
            .accessibilityLabel(Localization.commonAddToken)
            .transition(.opacity)
    }

    private var redesignedShareButton: some View {
        NavigationBarButton.share(action: viewModel.shareTokenDetails)
            .redesigned()
    }

    // MARK: - Legacy navigation

    private var rootViewWithToolbar: some View {
        rootView.toolbar {
            principalToolbarContent
            trailingToolbarContent
        }
    }

    private var principalToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            navigationBarTitle
        }
    }

    @ToolbarContentBuilder
    private var trailingToolbarContent: some ToolbarContent {
        NavigationToolbarButton.share(placement: .topBarTrailing, action: viewModel.shareTokenDetails)
            .redesigned()
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
                        .padding(.vertical, 12)
                        .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 16.0)

                chart
                    .hidden(viewModel.allDataLoadFailed)
                    .overlay(content: {
                        chartLoadFailedOverlay
                            .infinityFrame(axis: .horizontal)
                            .hidden(!viewModel.allDataLoadFailed)
                    })

                content
                    .hidden(viewModel.allDataLoadFailed)
                    .transition(.opacity)
            }
            .padding(.top, Constants.scrollViewContentTopInset)
            .readContentOffset(inCoordinateSpace: .named(CoordinateSpaceName.scrollViewFrame)) { contentOffset in
                scrollOffsetHandler.contentOffsetSubject.send(contentOffset)
                if viewModel.shouldShowPortfolioBlock {
                    isListContentObscured = contentOffset.y > Constants.scrollViewContentTopInset
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            portfolioBlock
        }
        .opacity(viewModel.overlayContentHidingProgress)
        .coordinateSpace(name: CoordinateSpaceName.scrollViewFrame)
        .bindAlert($viewModel.alert)
        .sheet(item: $viewModel.securityScoreDetailsViewModel) { detailsViewModel in
            MarketsTokenDetailsSecurityScoreDetailsRedesignedView(viewModel: detailsViewModel)
        }
        .animation(.default, value: viewModel.state)
        .animation(.default, value: viewModel.isLoading)
        .animation(.default, value: viewModel.allDataLoadFailed)
    }

    private var header: some View {
        headerRedesign
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
            MarketsHistoryChartViewRedesign(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var chartLoadFailedOverlay: some View {
        TangemUnableToLoadDataView(
            isButtonBusy: viewModel.isLoading,
            retryButtonAction: viewModel.loadDetailedInfo
        )
    }

    @ViewBuilder
    private var content: some View {
        MarketsTokenDetailsContentViewRedesign(viewModel: viewModel)
    }

    private var backgroundColor: Color {
        return Color.Tangem.Surface.level2
    }

    @ViewBuilder
    private var portfolioBlock: some View {
        if viewModel.portfolioBlockState.isVisible {
            MarketsPortfolioBlockView(
                state: viewModel.portfolioBlockState,
                iconURL: viewModel.iconURL,
                onAddTap: viewModel.onTapAddToPortfolioPromo,
                onAddFundsTap: viewModel.onAddFundsTap,
                onExpandTap: viewModel.onExpandPortfolioBlockTap
            )
            .padding(.horizontal, .unit(.x4))
            .padding(.vertical, .unit(.x2))
            .background(alignment: .bottom) {
                LinearGradient.Tangem.Common.tokenDetailsMarketPrice
                    .padding(.top, -Constants.shadowTopExtension)
                    .ignoresSafeArea()
            }
            .transition(.portfolioBlock)
        }
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsView {
    enum Constants {
        static let chartHeight = 200.0
        static let scrollViewContentTopInset = 14.0
        static let scrollViewVerticalPadding = 16.0
        static let shadowTopExtension = 60.0
    }

    enum CoordinateSpaceName {
        private static let prefix = "MarketsTokenDetailsView.CoordinateSpaceName."

        static let scrollViewFrame = prefix + "scrollViewFrame"
    }
}

private extension Animation {
    static let footerOpacity = Animation.curve(.easeOutEmphasized, duration: 0.3)
}

private extension AnyTransition {
    static let portfolioBlock = AnyTransition.asymmetric(
        insertion: .offset(y: 200).combined(with: .opacity.animation(.footerOpacity.delay(0.2))),
        removal: .offset(y: 200).combined(with: .opacity.animation(.footerOpacity))
    )
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
