//
//  MainHorizontalPagingScrollView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import func TangemFoundation.clamp
import TangemUI

struct MainHorizontalPagingScrollView: View {
    let userWalletPageBuilders: [MainUserWalletPageBuilder]
    let selectedCardIndex: Binding<Int>
    let refreshScrollViewStateObject: RefreshScrollViewStateObject
    let isPullToRefreshRunning: Bool
    let scanQRCodeAction: () -> Void
    let detailsAction: () -> Void

    @State private var userWalletIndexToScrollAdjustedValues = [Int: ScrollAdjustedValues]()

    @State private var bottomOverlayHeight = CGFloat.zero
    @State private var contentFooterHeight = CGFloat.zero
    @State private var safeAreaInsetsTop = CGFloat.zero

    @ScaledMetric private var headerBalanceTextHeight = CGFloat.unit(.x12)

    @StateObject private var scrollDetector = ScrollDetector()

    var body: some View {
        ZStack(alignment: .bottom) {
            contentFooter
            horizontalScrollView
            bottomOverlay
        }
        .ignoresSafeArea(edges: .bottom)
        .northernLightsBackground(
            backgroundColor: .Tangem.Surface.level2,
            opacity: selectedUserWalletScrollAdjustedValues.backgroundOpacity
        )
        .redesignToolbar(
            pageBuilder: userWalletPageBuilders[selectedCardIndex.wrappedValue],
            principalContentOpacity: selectedUserWalletScrollAdjustedValues.navigationBarBalanceOpacity,
            principalContentOffset: selectedUserWalletScrollAdjustedValues.navigationBarBalanceOffsetY,
            scanQRCodeAction: scanQRCodeAction,
            detailsAction: detailsAction
        )
        .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.top) { safeAreaInsetsTop in
            self.safeAreaInsetsTop = safeAreaInsetsTop
        }
        .onAppear(perform: scrollDetector.startDetectingScroll)
        .onDisappear(perform: scrollDetector.stopDetectingScroll)
        .environmentObject(scrollDetector)
        .animation(.default, value: selectedCardIndex.wrappedValue)
    }

    @ViewBuilder
    private var horizontalScrollView: some View {
        if #available(iOS 17.0, *) {
            HorizontalPagingScrollView(
                userWalletPageBuilders: userWalletPageBuilders,
                selectedCardIndex: selectedCardIndex,
                bottomOverlayHeight: bottomOverlayHeight,
                contentFooterHeight: contentFooterHeight,
                refreshScrollViewStateObject: refreshScrollViewStateObject,
                isHorizontalScrollDisabled: isHorizontalScrollDisabled,
                onContentGeometryChanged: { index, contentGeometry in
                    var scrollAdjustedValues = userWalletIndexToScrollAdjustedValues[index, default: .initial]

                    let navigationBarProgress = clamp(-contentGeometry.contentOffsetY / headerBalanceTextHeight, min: 0, max: 1)

                    scrollAdjustedValues.navigationBarBalanceOpacity = navigationBarBalanceOpacity(for: navigationBarProgress)
                    scrollAdjustedValues.navigationBarBalanceOffsetY = navigationBarBalanceOffsetY(for: navigationBarProgress)
                    scrollAdjustedValues.backgroundOpacity = backgroundOpacity(for: contentGeometry.contentOffsetY)
                    scrollAdjustedValues.contentFooterOverlayIsVisible = contentGeometry.didScrollToBottom

                    userWalletIndexToScrollAdjustedValues[index] = scrollAdjustedValues
                }
            )
        } else {
            EmptyView()
        }
    }

    private var contentFooter: some View {
        ZStack {
            if selectedUserWalletScrollAdjustedValues.contentFooterOverlayIsVisible {
                userWalletPageBuilders[selectedCardIndex.wrappedValue]
                    .footerOverlay
                    .redesigned()
                    .padding(.top, Paddings.contentFooterTop)
                    .padding(.bottom, Paddings.contentFooterBottom)
                    .offset(y: -bottomOverlayHeight)
                    .onGeometryChange(for: CGFloat.self, of: \.size.height) { contentFooterHeight in
                        self.contentFooterHeight = contentFooterHeight
                    }
                    .transition(.opacity)
            }
        }
        .animation(.easeIn(duration: 0.1), value: selectedUserWalletScrollAdjustedValues.contentFooterOverlayIsVisible)
    }

    private var bottomOverlay: some View {
        userWalletPageBuilders[selectedCardIndex.wrappedValue]
            .bottomOverlay
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { bottomOverlayHeight in
                self.bottomOverlayHeight = bottomOverlayHeight
            }
    }

    private var isHorizontalScrollDisabled: Bool {
        isPullToRefreshRunning || selectedUserWalletScrollAdjustedValues.navigationBarBalanceOpacity >= 1
    }

    private var selectedUserWalletScrollAdjustedValues: ScrollAdjustedValues {
        userWalletIndexToScrollAdjustedValues[selectedCardIndex.wrappedValue, default: .initial]
    }

    private func navigationBarBalanceOpacity(for progress: CGFloat) -> CGFloat {
        pow(progress, 3)
    }

    private func navigationBarBalanceOffsetY(for progress: CGFloat) -> CGFloat {
        (1 - pow(progress, 3)) * Sizes.navigationBalanceMaxYOffset
    }

    private func backgroundOpacity(for contentOffsetY: CGFloat) -> CGFloat {
        let startY = safeAreaInsetsTop
        let endY = headerBalanceTextHeight
        let progress = clamp((startY - contentOffsetY) / (startY + endY), min: 0, max: 1)

        return 1 - pow(progress, 1.25)
    }
}

extension MainHorizontalPagingScrollView {
    @available(iOS 17.0, *)
    private struct HorizontalPagingScrollView: View {
        let userWalletPageBuilders: [MainUserWalletPageBuilder]

        let selectedCardIndex: Binding<Int>
        let scrollPositionID: Binding<Int?>

        let bottomOverlayHeight: CGFloat
        let contentFooterHeight: CGFloat

        let refreshScrollViewStateObject: RefreshScrollViewStateObject
        let isHorizontalScrollDisabled: Bool
        let onContentGeometryChanged: (Int, UserWalletView.ScrollContentGeometry) -> Void

        init(
            userWalletPageBuilders: [MainUserWalletPageBuilder],
            selectedCardIndex: Binding<Int>,
            bottomOverlayHeight: CGFloat,
            contentFooterHeight: CGFloat,
            refreshScrollViewStateObject: RefreshScrollViewStateObject,
            isHorizontalScrollDisabled: Bool,
            onContentGeometryChanged: @escaping (Int, UserWalletView.ScrollContentGeometry) -> Void,
        ) {
            self.userWalletPageBuilders = userWalletPageBuilders

            self.selectedCardIndex = selectedCardIndex
            scrollPositionID = Binding(selectedCardIndex)

            self.bottomOverlayHeight = bottomOverlayHeight
            self.contentFooterHeight = contentFooterHeight

            self.refreshScrollViewStateObject = refreshScrollViewStateObject
            self.isHorizontalScrollDisabled = isHorizontalScrollDisabled
            self.onContentGeometryChanged = onContentGeometryChanged
        }

        var body: some View {
            ScrollView(.horizontal) {
                LazyHStack(spacing: .zero) {
                    ForEach(indexed: userWalletPageBuilders.indexed()) { index, userWalletPageBuilder in
                        UserWalletView(
                            pageBuilder: userWalletPageBuilder,
                            refreshScrollViewStateObject: refreshScrollViewStateObject,
                            onContentGeometryChanged: { contentGeometry in
                                onContentGeometryChanged(index, contentGeometry)
                            },
                            bottomOverlayHeight: bottomOverlayHeight,
                            contentFooterHeight: contentFooterHeight,
                            totalPages: userWalletPageBuilders.count,
                            currentIndex: selectedCardIndex.wrappedValue
                        )
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: scrollPositionID)
            .scrollDisabled(isHorizontalScrollDisabled)
        }
    }
}

extension MainHorizontalPagingScrollView {
    enum Paddings {
        static let contentFooterTop = CGFloat.unit(.x10)
        static let contentFooterBottom = CGFloat.unit(.x5)
    }

    private enum Sizes {
        static let navigationBalanceMaxYOffset: CGFloat = 16.0
    }

    private struct ScrollAdjustedValues: Equatable {
        var navigationBarBalanceOpacity: CGFloat
        var navigationBarBalanceOffsetY: CGFloat
        var backgroundOpacity: CGFloat
        var contentFooterOverlayIsVisible: Bool

        static let initial = ScrollAdjustedValues(
            navigationBarBalanceOpacity: 1,
            navigationBarBalanceOffsetY: 0,
            backgroundOpacity: 1,
            contentFooterOverlayIsVisible: false
        )
    }
}

private extension View {
    func redesignToolbar(
        pageBuilder: MainUserWalletPageBuilder,
        principalContentOpacity: CGFloat,
        principalContentOffset: CGFloat,
        scanQRCodeAction: @escaping () -> Void,
        detailsAction: @escaping () -> Void
    ) -> some View {
        modifier(
            MainViewRedesignToolbar(
                principalContent: {
                    pageBuilder.navigation
                        .opacity(principalContentOpacity)
                        .offset(y: principalContentOffset)
                },
                scanQRCodeAction: scanQRCodeAction,
                detailsAction: detailsAction
            )
        )
    }
}
