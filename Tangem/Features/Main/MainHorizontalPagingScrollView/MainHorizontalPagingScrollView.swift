//
//  MainHorizontalPagingScrollView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import func TangemFoundation.clamp
import struct TangemFoundation.UserWalletId
import TangemUI

struct MainHorizontalPagingScrollView: View {
    let userWalletPageBuilders: [MainUserWalletPageBuilder]

    let selectedCardIndex: Binding<Int>
    let onSelectedCardChanged: (CardsInfoPageChangeReason) -> Void

    let pullToRefreshAction: @MainActor () async -> Void
    let isPullToRefreshRunning: Bool
    let scanQRCodeAction: () -> Void
    let detailsAction: () -> Void

    @State private var userWalletIDToScrollAdjustedValues = [UserWalletId: ScrollAdjustedValues]()

    @State private var bottomOverlayHeight = CGFloat.zero
    @State private var contentFooterHeight = CGFloat.zero
    @State private var safeAreaInsetsTop = CGFloat.zero

    @ScaledMetric private var headerBalanceTextHeight = CGFloat.unit(.x12)

    @StateObject private var scrollDetector = ScrollDetector()

    var body: some View {
        ZStack(alignment: .bottom) {
            contentFooter
            horizontalScrollView
            pagingIndicator
            bottomOverlay
        }
        .ignoresSafeArea(edges: .bottom)
        .northernLightsBackground(
            backgroundColor: .Tangem.Surface.level2,
            opacity: selectedUserWalletScrollAdjustedValues.backgroundOpacity
        )
        .redesignToolbar(
            pageBuilder: selectedUserWalletPageBuilder,
            principalContentOpacity: selectedUserWalletScrollAdjustedValues.navigationBarBalanceOpacity,
            principalContentOffset: selectedUserWalletScrollAdjustedValues.navigationBarBalanceOffsetY,
            trailingButtonsHaveLiquidGlassEffect: selectedUserWalletBalanceHasReachedNavigationBar,
            scanQRCodeAction: scanQRCodeAction,
            detailsAction: detailsAction
        )
        .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.top) { safeAreaInsetsTop in
            self.safeAreaInsetsTop = safeAreaInsetsTop
        }
        .onChange(of: userWalletPageBuilders.map(\.id)) { userWalletIDs in
            userWalletIDToScrollAdjustedValues = userWalletIDToScrollAdjustedValues.filter { userWalletIDs.contains($0.key) }
        }
        .onAppear(perform: scrollDetector.startDetectingScroll)
        .onDisappear(perform: scrollDetector.stopDetectingScroll)
        .environmentObject(scrollDetector)
    }

    @ViewBuilder
    private var horizontalScrollView: some View {
        if #available(iOS 17.0, *) {
            HorizontalPagingScrollView(
                userWalletPageBuilders: userWalletPageBuilders,
                selectedCardIndex: selectedCardIndex,
                onSelectedCardChanged: onSelectedCardChanged,
                containerGeometryProperties: UserWalletView.ContainerGeometryProperties(
                    safeAreaInsetsTop: safeAreaInsetsTop,
                    bottomOverlayHeight: bottomOverlayHeight,
                    contentFooterHeight: contentFooterHeight
                ),
                pullToRefreshAction: pullToRefreshAction,
                isHorizontalScrollDisabled: isHorizontalScrollDisabled,
                onContentPropertiesChanged: handleContentPropertiesChanged,
                onNormalizedOffsetYChanged: handleNormalizedOffsetYChanged
            )
            .id(userWalletPageBuilders.map(\.id))
        } else {
            HorizontalPagingScrollViewBackport(
                userWalletPageBuilders: userWalletPageBuilders,
                selectedCardIndex: selectedCardIndex,
                onSelectedCardChanged: onSelectedCardChanged,
                containerGeometryProperties: UserWalletView.ContainerGeometryProperties(
                    safeAreaInsetsTop: safeAreaInsetsTop,
                    bottomOverlayHeight: bottomOverlayHeight,
                    contentFooterHeight: contentFooterHeight
                ),
                pullToRefreshAction: pullToRefreshAction,
                isHorizontalScrollDisabled: isHorizontalScrollDisabled,
                onContentPropertiesChanged: handleContentPropertiesChanged,
                onNormalizedOffsetYChanged: handleNormalizedOffsetYChanged
            )
        }
    }

    @ViewBuilder
    private var pagingIndicator: some View {
        if userWalletPageBuilders.count > 1 {
            VStack(spacing: .zero) {
                TangemPagination(totalPages: userWalletPageBuilders.count, currentIndex: selectedUserWalletIndex)
                    .frame(height: .unit(.x8))
                    .offset(y: selectedUserWalletScrollAdjustedValues.pagingIndicatorOffsetY)
                    .opacity(selectedUserWalletScrollAdjustedValues.pagingIndicatorOpacity)

                Spacer()
            }
        }
    }

    private var contentFooter: some View {
        ZStack {
            if selectedUserWalletScrollAdjustedValues.contentFooterOverlayIsVisible {
                selectedUserWalletPageBuilder
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
        selectedUserWalletPageBuilder
            .bottomOverlay
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { bottomOverlayHeight in
                self.bottomOverlayHeight = bottomOverlayHeight
            }
    }

    private var isHorizontalScrollDisabled: Bool {
        if isPullToRefreshRunning || userWalletPageBuilders.count <= 1 {
            return true
        }

        return !selectedUserWalletScrollAdjustedValues.didScrollToTop
    }

    private var selectedUserWalletBalanceHasReachedNavigationBar: Bool {
        guard let nonInitialScrollAdjustedValues = userWalletIDToScrollAdjustedValues[selectedUserWalletID] else {
            return false
        }

        return nonInitialScrollAdjustedValues.navigationBarBalanceOpacity >= 1
    }

    private var selectedUserWalletScrollAdjustedValues: ScrollAdjustedValues {
        userWalletIDToScrollAdjustedValues[selectedUserWalletID, default: .initial]
    }

    private var selectedUserWalletID: UserWalletId {
        selectedUserWalletPageBuilder.id
    }

    private var selectedUserWalletPageBuilder: MainUserWalletPageBuilder {
        userWalletPageBuilders[selectedUserWalletIndex]
    }

    private var selectedUserWalletIndex: Int {
        guard userWalletPageBuilders.indices.contains(selectedCardIndex.wrappedValue) else {
            return 0
        }

        return selectedCardIndex.wrappedValue
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

    private func handleContentPropertiesChanged(
        userWalletID: UserWalletId,
        contentProperties: UserWalletView.ScrollContentProperties
    ) {
        var scrollAdjustedValues = userWalletIDToScrollAdjustedValues[userWalletID, default: .initial]

        let navigationBarProgress = clamp(-contentProperties.contentOffsetY / headerBalanceTextHeight, min: 0, max: 1)

        scrollAdjustedValues.didScrollToTop = contentProperties.contentOffsetY >= safeAreaInsetsTop - Sizes.scrolledToTopTolerance
        scrollAdjustedValues.navigationBarBalanceOpacity = navigationBarBalanceOpacity(for: navigationBarProgress)
        scrollAdjustedValues.navigationBarBalanceOffsetY = navigationBarBalanceOffsetY(for: navigationBarProgress)
        scrollAdjustedValues.pagingIndicatorOpacity = contentProperties.pagingIndicatorOpacity
        scrollAdjustedValues.backgroundOpacity = backgroundOpacity(for: contentProperties.contentOffsetY)
        scrollAdjustedValues.contentFooterOverlayIsVisible = contentProperties.didScrollToBottom

        userWalletIDToScrollAdjustedValues[userWalletID] = scrollAdjustedValues
    }

    private func handleNormalizedOffsetYChanged(userWalletID: UserWalletId, normalizedOffsetY: CGFloat, animation: Animation?) {
        var scrollAdjustedValues = userWalletIDToScrollAdjustedValues[userWalletID, default: .initial]

        scrollAdjustedValues.pagingIndicatorOffsetY = normalizedOffsetY

        withAnimation(animation) {
            userWalletIDToScrollAdjustedValues[userWalletID] = scrollAdjustedValues
        }
    }
}

extension MainHorizontalPagingScrollView {
    @available(iOS 17.0, *)
    private struct HorizontalPagingScrollView: View {
        let userWalletPageBuilders: [MainUserWalletPageBuilder]

        let selectedCardIndex: Binding<Int>
        let onSelectedCardChanged: (CardsInfoPageChangeReason) -> Void

        let containerGeometryProperties: UserWalletView.ContainerGeometryProperties

        let pullToRefreshAction: @MainActor () async -> Void
        let isHorizontalScrollDisabled: Bool
        let onContentPropertiesChanged: (UserWalletId, UserWalletView.ScrollContentProperties) -> Void
        let onNormalizedOffsetYChanged: (UserWalletId, CGFloat, Animation?) -> Void

        @State private var scrollPositionID: UserWalletId?

        init(
            userWalletPageBuilders: [MainUserWalletPageBuilder],
            selectedCardIndex: Binding<Int>,
            onSelectedCardChanged: @escaping (CardsInfoPageChangeReason) -> Void,
            containerGeometryProperties: UserWalletView.ContainerGeometryProperties,
            pullToRefreshAction: @MainActor @escaping () async -> Void,
            isHorizontalScrollDisabled: Bool,
            onContentPropertiesChanged: @escaping (UserWalletId, UserWalletView.ScrollContentProperties) -> Void,
            onNormalizedOffsetYChanged: @escaping (UserWalletId, CGFloat, Animation?) -> Void
        ) {
            self.userWalletPageBuilders = userWalletPageBuilders

            self.selectedCardIndex = selectedCardIndex
            _scrollPositionID = State(
                initialValue: Self.userWalletID(at: selectedCardIndex.wrappedValue, in: userWalletPageBuilders)
            )
            self.onSelectedCardChanged = onSelectedCardChanged

            self.containerGeometryProperties = containerGeometryProperties

            self.pullToRefreshAction = pullToRefreshAction
            self.isHorizontalScrollDisabled = isHorizontalScrollDisabled
            self.onContentPropertiesChanged = onContentPropertiesChanged
            self.onNormalizedOffsetYChanged = onNormalizedOffsetYChanged
        }

        var body: some View {
            ScrollView(.horizontal) {
                LazyHStack(spacing: .zero) {
                    ForEach(userWalletPageBuilders) { userWalletPageBuilder in
                        UserWalletView(
                            pageBuilder: userWalletPageBuilder,
                            showPagingIndicatorStub: userWalletPageBuilders.count > 1,
                            pullToRefreshAction: pullToRefreshAction,
                            onContentPropertiesChanged: { contentProperties in
                                onContentPropertiesChanged(userWalletPageBuilder.id, contentProperties)
                            },
                            onNormalizedOffsetYChanged: { normalizedOffsetY, animation in
                                onNormalizedOffsetYChanged(userWalletPageBuilder.id, normalizedOffsetY, animation)
                            },
                            containerGeometryProperties: containerGeometryProperties
                        )
                        .containerRelativeFrame(.horizontal)
                        .id(userWalletPageBuilder.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollPositionID)
            .scrollClipDisabled()
            .scrollBounceBehavior(.basedOnSize)
            .scrollDisabled(isHorizontalScrollDisabled)
            .onChange(of: scrollPositionID) { _, newScrollPositionID in
                updateSelectedCardIndexIfNeeded(from: newScrollPositionID)
            }
            .onChange(of: selectedCardIndex.wrappedValue) { _, newSelectedCardIndex in
                updateScrollPositionIDIfNeeded(from: newSelectedCardIndex)
            }
        }

        private func updateSelectedCardIndexIfNeeded(from newScrollPositionID: UserWalletId?) {
            guard
                let newScrollPositionID,
                let newSelectedCardIndex = userWalletPageBuilders.firstIndex(where: { $0.id == newScrollPositionID }),
                newSelectedCardIndex != selectedCardIndex.wrappedValue
            else {
                return
            }

            selectedCardIndex.wrappedValue = newSelectedCardIndex
            onSelectedCardChanged(.byGesture)
        }

        private func updateScrollPositionIDIfNeeded(from newSelectedCardIndex: Int) {
            guard
                let newScrollPositionID = Self.userWalletID(at: newSelectedCardIndex, in: userWalletPageBuilders),
                newScrollPositionID != scrollPositionID
            else {
                return
            }

            withAnimation(.easeInOut(duration: 0.25)) {
                scrollPositionID = newScrollPositionID
            }
        }

        private static func userWalletID(
            at index: Int,
            in userWalletPageBuilders: [MainUserWalletPageBuilder]
        ) -> UserWalletId? {
            guard userWalletPageBuilders.indices.contains(index) else { return nil }
            return userWalletPageBuilders[index].id
        }
    }
}

extension MainHorizontalPagingScrollView {
    enum Paddings {
        static let contentFooterTop = CGFloat.unit(.x10)
        static let contentFooterBottom = CGFloat.unit(.x5)
    }

    private enum Sizes {
        static let navigationBalanceMaxYOffset = CGFloat.unit(.x4)
        static let pullToRefreshThreshold: CGFloat = 150
        static let scrolledToTopTolerance: CGFloat = 0.5
    }

    private struct ScrollAdjustedValues: Equatable {
        var didScrollToTop: Bool
        var navigationBarBalanceOpacity: CGFloat
        var navigationBarBalanceOffsetY: CGFloat
        var pagingIndicatorOpacity: CGFloat
        var pagingIndicatorOffsetY: CGFloat
        var backgroundOpacity: CGFloat
        var contentFooterOverlayIsVisible: Bool

        static let initial = ScrollAdjustedValues(
            didScrollToTop: true,
            navigationBarBalanceOpacity: 1,
            navigationBarBalanceOffsetY: 0,
            pagingIndicatorOpacity: 0,
            pagingIndicatorOffsetY: 0,
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
        trailingButtonsHaveLiquidGlassEffect: Bool,
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
                trailingButtonsHaveLiquidGlassEffect: trailingButtonsHaveLiquidGlassEffect,
                scanQRCodeAction: scanQRCodeAction,
                detailsAction: detailsAction
            )
        )
    }
}
