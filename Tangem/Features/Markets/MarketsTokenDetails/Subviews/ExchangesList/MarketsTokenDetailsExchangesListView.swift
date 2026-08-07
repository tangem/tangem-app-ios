//
//  MarketsTokenDetailsExchangesListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct MarketsTokenDetailsExchangesListView: View {
    @ObservedObject var viewModel: MarketsTokenDetailsExchangesListViewModel

    @Environment(\.colorScheme) private var colorScheme

    @State private var isListContentObscured = false
    @State private var headerHeight: CGFloat = .zero
    @State private var safeArea: EdgeInsets = .init()

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    private var defaultBackgroundColor: Color {
        .Tangem.Surface.level2
    }

    private let scrollViewContentTopInset = 14.0
    private let navigationBarTitle = Localization.marketsTokenDetailsExchangesTitle

    var body: some View {
        rootView
            .if(!viewModel.isMarketsSheetStyle) { view in
                view.navigationTitle(navigationBarTitle)
            }
            .onOverlayContentStateChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] state in
                viewModel?.onOverlayContentStateChange(state)
            }
            .onOverlayContentProgressChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] progress in
                viewModel?.onOverlayContentProgressChange(progress)
            }
            .background(defaultBackgroundColor.ignoresSafeArea())
            .animation(.default, value: exchangeListAnimationValue)
            .ignoresSafeArea(.container, edges: .top) // Without it, the content won't go into the safe area top zone on over-scroll
            .readGeometry(\.safeAreaInsets, bindTo: $safeArea)
            .onAppear(perform: viewModel.loadExchangesList)
    }

    private var rootView: some View {
        ZStack(alignment: .top) {
            listContent
                .opacity(viewModel.overlayContentHidingProgress)

            VStack(spacing: 0) {
                if viewModel.isMarketsSheetStyle {
                    MarketsNavigationBar(
                        title: navigationBarTitle,
                        onBackButtonAction: viewModel.onBackButtonAction
                    )
                } else {
                    // Native navigation bar is used, so we install an invisible spacer to align the header below the navigation bar
                    Color.clear
                        .frame(height: safeArea.top)
                }

                header
                    .opacity(viewModel.overlayContentHidingProgress)
            }
            .background {
                MarketsNavigationBarBackgroundView(
                    backdropViewColor: defaultBackgroundColor,
                    overlayContentHidingProgress: viewModel.overlayContentHidingProgress,
                    isNavigationBarBackgroundBackdropViewHidden: viewModel.isNavigationBarBackgroundBackdropViewHidden,
                    isListContentObscured: isListContentObscured
                )
            }
            .readGeometry(\.size.height, bindTo: $headerHeight)
            .infinityFrame(axis: .vertical, alignment: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var header: some View {
        redesignedHeader
    }

    private var redesignedHeader: some View {
        HStack(spacing: .zero) {
            redesignedHeaderText(Localization.marketsTokenDetailsExchange)
                .accessibilityIdentifier(MarketsAccessibilityIdentifiers.exchangesListTitle)

            Spacer()

            HStack(spacing: .unit(.x3)) {
                redesignedHeaderText(Localization.marketsTokenDetailsVolume)

                redesignedHeaderText(Localization.marketsSelectorInterval24hTitle)
            }
        }
        .padding(.horizontal, .unit(.x7))
        .padding(.top, .unit(.x3))
        .padding(.bottom, .unit(.x2))
    }

    private func redesignedHeaderText(_ text: String) -> some View {
        Text(text)
            .style(Font.Tangem.Caption12.semibold, color: Color.Tangem.Text.Neutral.secondary)
    }

    @ViewBuilder
    private var listContent: some View {
        redesignedListContent
            .padding(.horizontal, .unit(.x4))
    }

    @ViewBuilder
    private var redesignedListContent: some View {
        switch viewModel.exchangesList {
        case .loading, .success:
            redesignedScrollContent

        case .failure:
            TangemUnableToLoadDataView(
                isButtonBusy: false,
                retryButtonAction: viewModel.reloadExchangesList
            )
            .infinityFrame()
            .padding(.top, headerHeight)
        }
    }

    private var redesignedScrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .unit(.x3)) {
                Color.clear
                    .frame(height: headerHeight)

                LazyVStack(spacing: 0) {
                    switch viewModel.exchangesList {
                    case .loading:
                        ForEach(0 ... max(viewModel.numberOfExchangesListedOn - 1, 0), id: \.self) { _ in
                            TangemTwoLineRowSkeletonView()
                        }

                    case .success(let itemsList):
                        ForEach(itemsList) { item in
                            MarketsTokenDetailsExchangeItemViewRedesign(info: item)
                        }

                    case .failure:
                        EmptyView()
                    }
                }
                .roundedBackground(with: .Tangem.Surface.level3, padding: 0, radius: .unit(.x5))
            }
            .readContentOffset(inCoordinateSpace: .named(CoordinateSpaceName.scrollViewFrame)) { contentOffset in
                isListContentObscured = contentOffset.y > scrollViewContentTopInset
            }
            .id(viewModel.exchangesList.value)
        }
        .coordinateSpace(name: CoordinateSpaceName.scrollViewFrame)
    }

    private var exchangeListAnimationValue: Int {
        switch viewModel.exchangesList {
        case .success(let value):
            value.hashValue
        case .failure(let error):
            error.localizedDescription.hashValue
        case .loading:
            0
        }
    }
}

extension MarketsTokenDetailsExchangesListView {
    private enum CoordinateSpaceName {
        private static let prefix = "MarketsTokenDetailsExchangesListView.CoordinateSpaceName."

        static let scrollViewFrame = prefix + "scrollViewFrame"
    }
}

#Preview {
    MarketsTokenDetailsExchangesListView(
        viewModel: .init(
            tokenId: "ethereum",
            numberOfExchangesListedOn: 5,
            presentationStyle: .marketsSheet,
            exchangesListLoader: MarketsTokenDetailsDataProvider(),
            onBackButtonAction: {}
        )
    )
}
