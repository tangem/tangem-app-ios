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
    @Environment(\.mainShtorkaSize) private var sheetSize
    @Environment(\.mainShtorkaContentIsCollapsed) private var isContentCollapsed

    @State private var headerHeight: CGFloat = .zero
    @State private var headerLeadingWidth: CGFloat = .zero
    @State private var headerTrailingWidth: CGFloat = .zero
    @State private var isListContentObscured = false

    @StateObject private var scrollOffsetHandler = ScrollViewOffsetHandler.marketTokenDetails(
        initialState: MarketsNavigationBarTitle.State(priceOpacity: nil, titleOffset: 0),
        labelOffset: Constants.scrollViewContentTopInset + Constants.scrollViewVerticalPadding
    )

    var body: some View {
        rootViewWithTitle
            .background {
                backgroundColor
                    .ignoresSafeArea(edges: .vertical)
            }
            .onAppear(perform: scrollOffsetHandler.onViewAppear)
            .if(sheetSize.isFeedSheet) { view in
                let content = view
                    // The screen scrolls its own content instead of dragging the sheet it is pushed in.
                    .presentationContentInteraction(.scrolls)
                    .toolbar(.hidden, for: .navigationBar)

                return Group {
                    if #available(iOS 18.0, *) {
                        content.containerBackground(.clear, for: .navigation)
                    } else {
                        content
                    }
                }
            }
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
        Group {
            if sheetSize.isFeedSheet {
                ZStack(alignment: .top) {
                    scrollView
                        .hiddenWhileCollapsed()

                    sheetNavigationBar
                        .readGeometry(\.size.height, bindTo: $headerHeight)
                }
            } else {
                legacyRootView
            }
        }
        .animation(.curve(.easeInOutRefined, duration: 0.5), value: viewModel.portfolioBlockState.isVisible)
        .animation(.curve(.easeInOutRefined, duration: 0.5), value: viewModel.isAddButtonVisible)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var legacyRootView: some View {
        ZStack {
            scrollView

            if viewModel.usesSheetNavigationHeader {
                navigationBar
            }
        }
    }

    @ViewBuilder
    private var sheetNavigationBar: some View {
        if isContentCollapsed {
            HStack(spacing: 0) {
                redesignedBackButton
                    .readGeometry(\.size.width, bindTo: $headerLeadingWidth)
                Spacer(minLength: 8)
                redesignedTrailingButtons
                    .readGeometry(\.size.width, bindTo: $headerTrailingWidth)
            }
            .overlay(alignment: .center) {
                sheetNavigationBarTitle
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
        } else {
            NavigationHeader(
                leadingContent: {
                    redesignedBackButton
                        .readGeometry(\.size.width, bindTo: $headerLeadingWidth)
                },
                principalContent: {
                    sheetNavigationBarTitle
                },
                trailingContent: {
                    redesignedTrailingButtons
                        .readGeometry(\.size.width, bindTo: $headerTrailingWidth)
                }
            )
        }
    }

    private var sheetNavigationBarTitle: some View {
        navigationBarTitle
            .padding(.horizontal, max(headerLeadingWidth, headerTrailingWidth) + Constants.titleToButtonSpacing)
            .allowsHitTesting(false)
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
        HStack(spacing: sheetSize.isFeedSheet ? 8 : 12) {
            if let priceAlertBellViewModel = viewModel.priceAlertBellViewModel {
                PriceAlertBellView(viewModel: priceAlertBellViewModel)
            }

            if sheetSize.isFeedSheet {
                redesignedShareButton
            }

            if viewModel.isMarketsSheetStyle, viewModel.isAddButtonVisible {
                redesignedAddButton
            }

            if !sheetSize.isFeedSheet {
                redesignedShareButton
            }
        }
    }

    private var redesignedAddButton: some View {
        NavigationBarButton.add(action: viewModel.onTapAddButton)
            .redesigned()
            .dimmed(!viewModel.isAddButtonEnabled)
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

        if viewModel.isAddButtonVisible {
            NavigationToolbarButton.add(placement: .topBarTrailing, action: viewModel.onTapAddButton)
                .redesigned()
                .dimmed(!viewModel.isAddButtonEnabled)
                .accessibilityLabel(Localization.commonAddToken)
        }
    }

    private var navigationBarTitle: some View {
        MarketsNavigationBarTitle(
            tokenName: viewModel.tokenName,
            price: viewModel.price,
            state: navigationBarTitleState,
            spacing: isContentCollapsed ? 4 : 0,
            fadesOverflow: sheetSize.isFeedSheet
        )
    }

    private var navigationBarTitleState: MarketsNavigationBarTitle.State {
        guard !isContentCollapsed else {
            return MarketsNavigationBarTitle.State(
                priceOpacity: 1,
                titleOffset: ScrollViewOffsetHandler.MarketsTokenDetailsConstants.maxTitleOffset
            )
        }

        return scrollOffsetHandler.state
    }

    private var scrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .center, spacing: Constants.scrollViewVerticalPadding) {
                // Using plain old overlay + dummy `Color.clear` spacer in the scroll view due to the buggy
                // `safeAreaInset(edge:alignment:spacing:content:)` iOS 15+ API which has both layout and touch-handling issues
                if !sheetSize.isFeedSheet {
                    Color.clear
                        .frame(height: headerHeight)
                }

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
                    .transition(.opacity)
            }
            .padding(.top, Constants.scrollViewContentTopInset + (sheetSize.isFeedSheet ? headerHeight : 0))
            .readContentOffset(inCoordinateSpace: .named(CoordinateSpaceName.scrollViewFrame)) { contentOffset in
                scrollOffsetHandler.contentOffsetSubject.send(contentOffset)
                if viewModel.showsPortfolioActions {
                    isListContentObscured = contentOffset.y > Constants.scrollViewContentTopInset
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            portfolioBlock
        }
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
            MarketsHistoryChartView(viewModel: viewModel)
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
        MarketsTokenDetailsContentView(viewModel: viewModel)
    }

    private var backgroundColor: Color {
        !sheetSize.isNonFullFeedSheet ? DesignSystem.Color.bgPrimary : .clear
    }

    @ViewBuilder
    private var portfolioBlock: some View {
        if viewModel.portfolioBlockState.isVisible, !sheetSize.isNonFullFeedSheet {
            MarketsPortfolioBlockView(
                state: viewModel.portfolioBlockState,
                iconURL: viewModel.iconURL,
                onAddTap: viewModel.onTapAddToPortfolioPromo,
                onAddFundsTap: viewModel.onAddFundsTap,
                onExpandTap: viewModel.onExpandPortfolioBlockTap
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(alignment: .bottom) {
                // [REDACTED_TODO_COMMENT]
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
        static let titleToButtonSpacing = 8.0
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
        restrictedForCountry: nil
    )

    return MarketsTokenDetailsView(viewModel: .init(
        tokenInfo: tokenInfo,
        presentationStyle: .marketsSheet,
        showsPortfolioActions: true,
        dataProvider: .init(),
        marketsQuotesUpdateHelper: CommonMarketsQuotesUpdateHelper(),
        coordinator: nil
    ))
}
