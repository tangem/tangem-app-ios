//
//  MarketsMainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import Combine
import BlockchainSdk
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemFoundation

struct MarketsMainView: View {
    @ObservedObject var viewModel: MarketsMainViewModel

    @StateObject private var navigationControllerConfigurator = MarketsViewNavigationControllerConfigurator()

    @Environment(\.mainWindowSize) private var mainWindowSize

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver
    @Injected(\.overlayContentContainer) private var overlayContentContainer: OverlayContentContainer

    @State private var headerHeight: CGFloat = .zero
    @State private var defaultListOverlayTotalHeight: CGFloat = .zero
    @State private var defaultListOverlayRatingHeaderHeight: CGFloat = .zero
    @State private var searchResultListOverlayTotalHeight: CGFloat = .zero
    @State private var listOverlayVerticalOffset: CGFloat = .zero
    @State private var listOverlayTitleOpacity: CGFloat = 1.0
    @State private var isListContentObscured = false
    @State private var responderChainIntrospectionTrigger = UUID()

    private var defaultBackgroundColor: Color { Colors.Background.primary }

    private let scrollTopAnchorId = UUID()
    private let scrollViewFrameCoordinateSpaceName = UUID()

    private var overlayHeight: CGFloat { showSearchResult ? searchResultListOverlayTotalHeight : defaultListOverlayTotalHeight }
    private var showSearchResult: Bool { viewModel.isSearching }

    var body: some View {
        rootView
            .onAppear {
                viewModel.onViewAppear()
            }
            .onDisappear(perform: viewModel.onViewDisappear)
            .onOverlayContentProgressChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] progress in
                viewModel?.onOverlayContentProgressChange(progress)

                if progress < 1 {
                    UIResponder.current?.resignFirstResponder()
                }
            }
            .onOverlayContentStateChange(overlayContentStateObserver: overlayContentStateObserver) { [weak viewModel] state in
                viewModel?.onOverlayContentStateChange(state)
            }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            Group {
                if showSearchResult {
                    searchResultView
                } else {
                    defaultWidgetsView
                }
            }
            .opacity(viewModel.overlayContentHidingProgress) // Hides list content on bottom sheet minimizing
            .scrollDismissesKeyboardCompat(.immediately)

            navigationBarBackground

            MainBottomSheetHeaderView(viewModel: viewModel.headerViewModel)
                .readGeometry(\.size.height, bindTo: $headerHeight)
                .infinityFrame(axis: .vertical, alignment: .top)
        }
        .background(defaultBackgroundColor.ignoresSafeArea())
        // This dummy title won't be shown in the UI, but it's required since without it UIKit will allocate
        // another `UINavigationBar` instance for use on the `Markets Token Details` page, and the code inside
        // `navigationControllerConfigurator` won't hide the navigation bar on that page (`Markets Token Details`)
        .navigationTitle("MarketsMainView")
        .navigationBarTitleDisplayMode(.inline)
        .onWillAppear {
            navigationControllerConfigurator.setCornerRadius(overlayContentContainer.cornerRadius)
            // `UINavigationBar` may be installed into the view hierarchy quite late;
            // therefore, we're triggering introspection in the `viewWillAppear` callback
            responderChainIntrospectionTrigger = UUID()
        }
        .onAppear {
            navigationControllerConfigurator.setCornerRadius(overlayContentContainer.cornerRadius)
            // `UINavigationBar` may be installed into the view hierarchy quite late;
            // therefore, we're triggering introspection in the `onAppear` callback
            responderChainIntrospectionTrigger = UUID()
        }
        .introspectResponderChain(
            introspectedType: UINavigationController.self,
            updateOnChangeOf: responderChainIntrospectionTrigger,
            action: navigationControllerConfigurator.configure(_:)
        )
    }

    @ViewBuilder
    private var navigationBarBackground: some View {
        MarketsNavigationBarBackgroundView(
            backdropViewColor: defaultBackgroundColor,
            overlayContentHidingProgress: viewModel.overlayContentHidingProgress,
            isNavigationBarBackgroundBackdropViewHidden: viewModel.isNavigationBarBackgroundBackdropViewHidden,
            isListContentObscured: isListContentObscured
        ) {
            Group {
                if showSearchResult {
                    searchResultListOverlay
                } else {
                    defaultListOverlay
                }
            }
        }
        .frame(height: headerHeight + overlayHeight)
        .offset(y: listOverlayVerticalOffset)
        .infinityFrame(axis: .vertical, alignment: .top)
    }

    @ViewBuilder
    private var defaultWidgetsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.widgetItems, id: \.id) { item in
                switch item {
                case .banner(let widgetModel):
                    MarketsMainWidgetItemView(
                        title: widgetModel.headerTitle,
                        content: MarketsBannerWidgetView()
                    )
                case .news(_):
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    private var searchResultView: some View {
        noResultsStateView
    }

    @ViewBuilder
    private var defaultListOverlay: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .center, spacing: .zero) {
                VStack(alignment: .leading, spacing: .zero) {
                    Text("Market & News")
                        .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                        .opacity(listOverlayTitleOpacity)

                    Text("21 October")
                        .style(Fonts.Bold.title1, color: Colors.Text.tertiary)
                        .opacity(listOverlayTitleOpacity)
                }

                Spacer()
            }
        }
        .infinityFrame(axis: .horizontal)
        .padding(.top, Constants.listOverlayTopInset)
        .padding(.bottom, Constants.listOverlayBottomInset)
        .padding(.horizontal, Constants.defaultHorizontalInset)
        .readGeometry(\.size.height, bindTo: $defaultListOverlayTotalHeight)
    }

    @ViewBuilder
    private var searchResultListOverlay: some View {
        Text(Localization.marketsSearchResultTitle)
            .style(Fonts.Bold.title3, color: Colors.Text.primary1)
            .opacity(listOverlayTitleOpacity)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Constants.listOverlayTopInset)
            .padding(.horizontal, Constants.defaultHorizontalInset)
            .readGeometry(\.size.height, bindTo: $searchResultListOverlayTotalHeight)
    }

    private var noResultsStateView: some View {
        Text(Localization.marketsSearchTokenNoResultTitle)
            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, Constants.defaultHorizontalInset)
    }

    private func updateListOverlayAppearance(contentOffset: CGPoint) {
        // Early exit to prevent list overlay 'jiggling' due to small fluctuations of content offset while dragging the list
        if overlayContentContainer.isScrollViewLocked {
            listOverlayVerticalOffset = .zero
            listOverlayTitleOpacity = 1.0
            isListContentObscured = false
            return
        }

        let maxOffset: CGFloat
        let offSet: CGFloat

        if showSearchResult {
            maxOffset = searchResultListOverlayTotalHeight
            offSet = clamp(contentOffset.y, min: .zero, max: maxOffset)
        } else {
            maxOffset = max(
                defaultListOverlayTotalHeight - defaultListOverlayRatingHeaderHeight - Constants.listOverlayBottomInset,
                .zero
            )
            offSet = clamp(contentOffset.y, min: .zero, max: maxOffset)
        }

        listOverlayTitleOpacity = maxOffset.isZero ? 1.0 : 1.0 - offSet / maxOffset // Division by zero protection
        listOverlayVerticalOffset = -offSet
        isListContentObscured = contentOffset.y >= (maxOffset + Constants.listOverlayBottomInset)
    }
}

// MARK: - Constants

private extension MarketsMainView {
    enum Constants {
        static let defaultHorizontalInset = 16.0
        static let listOverlayTopInset = 10.0
        static let listOverlayBottomInset = 12.0
    }
}
