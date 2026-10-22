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
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct MarketsTokenDetailsExchangesListView: View {
    @ObservedObject var viewModel: MarketsTokenDetailsExchangesListViewModel

    @Environment(\.mainShtorkaSize) private var sheetSize

    @State private var isListContentObscured = false
    @State private var headerHeight: CGFloat = .zero
    @State private var columnHeaderHeight: CGFloat = .zero
    @State private var safeArea: EdgeInsets = .init()

    private var defaultBackgroundColor: Color {
        DesignSystem.Color.bgPrimary
    }

    private var usesCustomNavigationBar: Bool {
        sheetSize.isFeedSheet || viewModel.isMarketsSheetStyle
    }

    private let scrollViewContentTopInset = 14.0
    private let navigationBarTitle = Localization.marketsTokenDetailsExchangesTitle

    var body: some View {
        rootView
            .if(!usesCustomNavigationBar) { view in
                view.navigationTitle(navigationBarTitle)
            }
            .background {
                if !sheetSize.isNonFullFeedSheet {
                    defaultBackgroundColor.ignoresSafeArea()
                }
            }
            .animation(.default, value: exchangeListAnimationValue)
            .if(!sheetSize.isFeedSheet) { view in
                view.ignoresSafeArea(.container, edges: .top)
            }
            .if(usesCustomNavigationBar) { view in
                view
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationBarBackButtonHidden()
            }
            .readGeometry(\.safeAreaInsets, bindTo: $safeArea)
            .onAppear(perform: viewModel.loadExchangesList)
    }

    private var rootView: some View {
        ZStack(alignment: .top) {
            listContent
                .hiddenWhileCollapsed()

            VStack(spacing: 0) {
                if sheetSize.isFeedSheet {
                    NavigationHeader(
                        leadingContent: { NavigationBarButton.back(action: viewModel.onBackButtonAction).redesigned() },
                        principalContent: {
                            Text(navigationBarTitle)
                                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        },
                        trailingContent: { EmptyView() }
                    )
                    .backgroundBottomInset(sheetSize.isCollapsedFeedSheet ? 0 : columnHeaderHeight)
                } else if viewModel.isMarketsSheetStyle {
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
                    .hiddenWhileCollapsed()
                    .readGeometry(\.size.height, bindTo: $columnHeaderHeight)
            }
            .background {
                if !sheetSize.isFeedSheet {
                    MarketsNavigationBarBackgroundView(isListContentObscured: isListContentObscured)
                }
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

            HStack(spacing: 12) {
                redesignedHeaderText(Localization.marketsTokenDetailsVolume)

                redesignedHeaderText(Localization.marketsSelectorInterval24hTitle)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func redesignedHeaderText(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
    }

    @ViewBuilder
    private var listContent: some View {
        redesignedListContent
            .padding(.horizontal, 16)
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
            VStack(spacing: 12) {
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
                            MarketsTokenDetailsExchangeItemView(info: item)
                        }

                    case .failure:
                        EmptyView()
                    }
                }
                .roundedBackground(with: DesignSystem.Color.bgSecondary, padding: 0, radius: 20)
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
