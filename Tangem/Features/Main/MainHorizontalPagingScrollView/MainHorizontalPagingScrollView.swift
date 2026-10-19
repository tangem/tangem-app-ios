//
//  MainHorizontalPagingScrollView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUI
import TangemAssets
import TangemUIUtils

struct MainHorizontalPagingScrollView: View {
    let userWalletPageBuilders: [MainUserWalletPageBuilder]

    let selectedCardIndex: Binding<Int>
    let onSelectedCardChanged: (CardsInfoPageChangeReason) -> Void

    let pullToRefreshAction: @MainActor (UserWalletId) -> Void
    let refreshingUserWalletIDs: Set<UserWalletId>
    let scanQRCodeAction: () -> Void
    let detailsAction: () -> Void

    @State private var userWalletIDToScrollAdjustedValues = [UserWalletId: ScrollAdjustedValues]()
    @State private var pagingIndicatorAnimationIsBlocked = true

    /// `refreshingUserWalletIDs` applied inside an animated transaction: the indicator sits above the refresh control
    /// and must collapse on the same curve. Pages read `refreshingUserWalletIDs` directly — their refresh guard must
    /// see the flip immediately.
    @State private var animatedRefreshingUserWalletIDs = Set<UserWalletId>()

    /// Horizontal position of the pager, measured in page widths: `1.5` means the swipe is halfway between the second
    /// and the third page. `nil` until the pager reports it.
    @State private var pagePosition: CGFloat?

    @Environment(\.mainShtorkaBottomInset) private var mainShtorkaBottomInset

    @State private var legacyBottomOverlayHeight = CGFloat.zero
    @State private var contentFooterHeight = CGFloat.zero
    @State private var safeAreaInsetsTop = CGFloat.zero
    @State private var verticalBarInsets = EdgeInsets()

    @ScaledMetric private var headerBalanceTextHeight = CGFloat(48)

    @StateObject private var scrollDetector = ScrollDetector()

    @Environment(\.verticalBarEdge) private var verticalBarEdge

    var body: some View {
        ZStack(alignment: .bottom) {
            contentFooter
            horizontalScrollView
            pagingIndicator
            bottomOverlay
        }
        .ignoresSafeArea(edges: .bottom)
        .ignoresVerticalBarSafeArea()
        .northernLightsBackground(
            backgroundColor: DesignSystem.Color.bgPrimary,
            opacity: blendedValue(\.backgroundOpacity)
        )
        .mainTopNavigation(
            scanQRCodeAction: scanQRCodeAction,
            detailsAction: detailsAction,
            actionsHaveBackground: navigationActionsHaveBackground
        ) {
            selectedUserWalletPageBuilder.navigation
                .opacity(selectedUserWalletScrollAdjustedValues.navigationBarBalanceOpacity)
                .offset(y: selectedUserWalletScrollAdjustedValues.navigationBarBalanceOffsetY)
        }
        .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.top) { safeAreaInsetsTop in
            self.safeAreaInsetsTop = safeAreaInsetsTop
        }
        .onGeometryChange(for: EdgeInsets.self, of: verticalBarInsets(in:)) { verticalBarInsets in
            self.verticalBarInsets = verticalBarInsets
        }
        .onChange(of: userWalletPageBuilders.map(\.id)) { userWalletIDs in
            pagingIndicatorAnimationIsBlocked = true
            pagePosition = nil
            userWalletIDToScrollAdjustedValues = userWalletIDToScrollAdjustedValues.filter { userWalletIDs.contains($0.key) }
        }
        .onChange(of: refreshingUserWalletIDs) { refreshingUserWalletIDs in
            withAnimation(UserWalletView.RefreshableConstants.refreshEndAnimation) {
                animatedRefreshingUserWalletIDs = refreshingUserWalletIDs
            }
        }
        .onAppear {
            animatedRefreshingUserWalletIDs = refreshingUserWalletIDs
            scrollDetector.startDetectingScroll()
        }
        .onDisappear(perform: scrollDetector.stopDetectingScroll)
        .environmentObject(scrollDetector)
    }

    private func verticalBarInsets(in geometryProxy: GeometryProxy) -> EdgeInsets {
        switch verticalBarEdge {
        case .leading: EdgeInsets(top: .zero, leading: geometryProxy.safeAreaInsets.leading, bottom: .zero, trailing: .zero)
        case .trailing: EdgeInsets(top: .zero, leading: .zero, bottom: .zero, trailing: geometryProxy.safeAreaInsets.trailing)
        case nil: EdgeInsets()
        }
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
                    contentFooterHeight: contentFooterHeight,
                    verticalBarInsets: verticalBarInsets
                ),
                pullToRefreshAction: pullToRefreshAction,
                refreshingUserWalletIDs: refreshingUserWalletIDs,
                isHorizontalScrollDisabled: isHorizontalScrollDisabled,
                onContentPropertiesChanged: handleContentPropertiesChanged,
                onPagingIndicatorOffsetChanged: handlePagingIndicatorOffsetChanged,
                onPagePositionChanged: handlePagePositionChanged
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
                    contentFooterHeight: contentFooterHeight,
                    verticalBarInsets: verticalBarInsets
                ),
                pullToRefreshAction: pullToRefreshAction,
                refreshingUserWalletIDs: refreshingUserWalletIDs,
                isHorizontalScrollDisabled: isHorizontalScrollDisabled,
                onContentPropertiesChanged: handleContentPropertiesChanged,
                onPagingIndicatorOffsetChanged: handlePagingIndicatorOffsetChanged,
                onPagePositionChanged: handlePagePositionChanged
            )
        }
    }

    @ViewBuilder
    private var pagingIndicator: some View {
        if userWalletPageBuilders.count > 1 {
            VStack(spacing: .zero) {
                TangemPagination(totalPages: userWalletPageBuilders.count, currentIndex: pagingIndicatorCurrentIndex)
                    .frame(height: 32)
                    .offset(y: blendedPagingIndicatorOffsetY ?? .zero)
                    .transaction { transaction in
                        guard pagingIndicatorAnimationIsBlocked else { return }
                        transaction.animation = nil
                    }
                    // Hidden until some page has said where the indicator belongs. Opacity is reported by a different
                    // callback than the offset, so without this it can turn visible while still parked at zero.
                    .opacity(blendedPagingIndicatorOffsetY == nil ? .zero : blendedValue(\.pagingIndicatorOpacity))

                Spacer()
            }
            .verticalBarSafeAreaPadding(verticalBarInsets)
            .task(id: userWalletPageBuilders.map(\.id)) {
                await Task.yield()
                pagingIndicatorAnimationIsBlocked = false
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
        .verticalBarSafeAreaPadding(verticalBarInsets)
        .animation(.easeIn(duration: 0.1), value: selectedUserWalletScrollAdjustedValues.contentFooterOverlayIsVisible)
    }

    private var bottomOverlay: some View {
        selectedUserWalletPageBuilder
            .bottomOverlay
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { bottomOverlayHeight in
                legacyBottomOverlayHeight = bottomOverlayHeight
            }
    }

    private var bottomOverlayHeight: CGFloat {
        max(legacyBottomOverlayHeight, mainShtorkaBottomInset)
    }

    private var isHorizontalScrollDisabled: Bool {
        if userWalletPageBuilders.count <= 1 {
            return true
        }

        return !selectedUserWalletScrollAdjustedValues.didScrollToTop
    }

    private var navigationActionsHaveBackground: Bool {
        verticalBarEdge != nil || selectedUserWalletBalanceHasReachedNavigationBar
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

    /// The paging indicator and the background belong to no single page, so they are driven by the page position
    /// instead of the selected page: they track the finger through a swipe rather than snapping when selection flips.
    private var blender: PagingPositionBlender {
        PagingPositionBlender(
            position: pagePosition,
            fallbackIndex: selectedUserWalletIndex,
            pageCount: userWalletPageBuilders.count
        )
    }

    private var pagingIndicatorCurrentIndex: Int {
        blender.nearestIndex
    }

    /// `nil` until at least one of the pages involved has reported its geometry, which is the state a freshly inserted
    /// page starts in. Zero is not a usable stand-in: it would park the indicator at the top of the screen.
    private var blendedPagingIndicatorOffsetY: CGFloat? {
        blender(pagingIndicatorOffsetY(at:)) ?? pagingIndicatorOffsetY(at: selectedUserWalletIndex)
    }

    private func blendedValue(_ keyPath: KeyPath<ScrollAdjustedValues, CGFloat>) -> CGFloat {
        blender { scrollAdjustedValues(at: $0)?[keyPath: keyPath] }
            ?? selectedUserWalletScrollAdjustedValues[keyPath: keyPath]
    }

    /// The height of a running refresh is added here rather than reported by the page. The pager owns that state, so
    /// the offset cannot outlive the refresh even when the page is rebuilt mid-flight.
    private func pagingIndicatorOffsetY(at index: Int) -> CGFloat? {
        guard let baseOffsetY = scrollAdjustedValues(at: index)?.pagingIndicatorBaseOffsetY else { return nil }
        return baseOffsetY + refreshControlHeight(at: index)
    }

    private func refreshControlHeight(at index: Int) -> CGFloat {
        UserWalletView.RefreshableConstants.refreshControlHeight(
            isRefreshing: isRefreshing(at: index),
            dragRefreshControlHeight: scrollAdjustedValues(at: index)?.dragRefreshControlHeight ?? .zero
        )
    }

    private func isRefreshing(at index: Int) -> Bool {
        guard let pageBuilder = userWalletPageBuilders[safe: index] else { return false }
        return animatedRefreshingUserWalletIDs.contains(pageBuilder.id)
    }

    private func scrollAdjustedValues(at index: Int) -> ScrollAdjustedValues? {
        userWalletPageBuilders[safe: index].flatMap { userWalletIDToScrollAdjustedValues[$0.id] }
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

    private func handlePagePositionChanged(_ pagePosition: CGFloat) {
        // The programmatic scroll animates `scrollPositionID`, and the resulting geometry updates would otherwise
        // animate the paging indicator a second time on top of the scroll animation.
        withTransaction(Transaction.withoutAnimations()) {
            self.pagePosition = pagePosition
        }
    }

    private func handlePagingIndicatorOffsetChanged(
        userWalletID: UserWalletId,
        pagingIndicatorOffset: UserWalletView.PagingIndicatorOffset
    ) {
        var scrollAdjustedValues = userWalletIDToScrollAdjustedValues[userWalletID, default: .initial]

        scrollAdjustedValues.pagingIndicatorBaseOffsetY = pagingIndicatorOffset.baseOffsetY
        scrollAdjustedValues.dragRefreshControlHeight = pagingIndicatorOffset.dragRefreshControlHeight

        userWalletIDToScrollAdjustedValues[userWalletID] = scrollAdjustedValues
    }
}

extension MainHorizontalPagingScrollView {
    @available(iOS 17.0, *)
    private struct HorizontalPagingScrollView: View {
        let userWalletPageBuilders: [MainUserWalletPageBuilder]

        let selectedCardIndex: Binding<Int>
        let onSelectedCardChanged: (CardsInfoPageChangeReason) -> Void

        let containerGeometryProperties: UserWalletView.ContainerGeometryProperties

        let pullToRefreshAction: @MainActor (UserWalletId) -> Void
        let refreshingUserWalletIDs: Set<UserWalletId>
        let isHorizontalScrollDisabled: Bool
        let onContentPropertiesChanged: (UserWalletId, UserWalletView.ScrollContentProperties) -> Void
        let onPagingIndicatorOffsetChanged: (UserWalletId, UserWalletView.PagingIndicatorOffset) -> Void
        let onPagePositionChanged: (CGFloat) -> Void

        @State private var scrollPositionID: UserWalletId?
        @State private var pageWidth = CGFloat.zero

        /// `nil` until the content reports its own frame. The width of the scroll view is reported first, and a
        /// placeholder here would put the pager at page zero for that frame no matter which page is selected.
        @State private var contentMinX: CGFloat?

        init(
            userWalletPageBuilders: [MainUserWalletPageBuilder],
            selectedCardIndex: Binding<Int>,
            onSelectedCardChanged: @escaping (CardsInfoPageChangeReason) -> Void,
            containerGeometryProperties: UserWalletView.ContainerGeometryProperties,
            pullToRefreshAction: @MainActor @escaping (UserWalletId) -> Void,
            refreshingUserWalletIDs: Set<UserWalletId>,
            isHorizontalScrollDisabled: Bool,
            onContentPropertiesChanged: @escaping (UserWalletId, UserWalletView.ScrollContentProperties) -> Void,
            onPagingIndicatorOffsetChanged: @escaping (UserWalletId, UserWalletView.PagingIndicatorOffset) -> Void,
            onPagePositionChanged: @escaping (CGFloat) -> Void
        ) {
            self.userWalletPageBuilders = userWalletPageBuilders

            self.selectedCardIndex = selectedCardIndex
            self.onSelectedCardChanged = onSelectedCardChanged

            self.containerGeometryProperties = containerGeometryProperties

            self.pullToRefreshAction = pullToRefreshAction
            self.refreshingUserWalletIDs = refreshingUserWalletIDs
            self.isHorizontalScrollDisabled = isHorizontalScrollDisabled
            self.onContentPropertiesChanged = onContentPropertiesChanged
            self.onPagingIndicatorOffsetChanged = onPagingIndicatorOffsetChanged
            self.onPagePositionChanged = onPagePositionChanged
        }

        var body: some View {
            ScrollView(.horizontal) {
                LazyHStack(spacing: .zero) {
                    ForEach(userWalletPageBuilders) { userWalletPageBuilder in
                        UserWalletView(
                            pageBuilder: userWalletPageBuilder,
                            showPagingIndicatorStub: userWalletPageBuilders.count > 1,
                            isRefreshing: refreshingUserWalletIDs.contains(userWalletPageBuilder.id),
                            pullToRefreshAction: { pullToRefreshAction(userWalletPageBuilder.id) },
                            onContentPropertiesChanged: { contentProperties in
                                onContentPropertiesChanged(userWalletPageBuilder.id, contentProperties)
                            },
                            onPagingIndicatorOffsetChanged: { pagingIndicatorOffset in
                                onPagingIndicatorOffsetChanged(userWalletPageBuilder.id, pagingIndicatorOffset)
                            },
                            containerGeometryProperties: containerGeometryProperties
                        )
                        .containerRelativeFrame(.horizontal)
                        .id(userWalletPageBuilder.id)
                    }
                }
                .scrollTargetLayout()
                .onGeometryChange(for: CGFloat.self, of: contentMinX(in:)) { contentMinX in
                    self.contentMinX = contentMinX
                    reportPagePositionIfPossible()
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollPositionID)
            .scrollClipDisabled()
            .scrollBounceBehavior(.basedOnSize)
            .scrollDisabled(isHorizontalScrollDisabled)
            .coordinateSpace(.named(CoordinateSpaceIdentifier.horizontalScrollView))
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { pageWidth in
                self.pageWidth = pageWidth
                reportPagePositionIfPossible()
            }
            .onChange(of: scrollPositionID) { _, newScrollPositionID in
                updateSelectedCardIndexIfNeeded(from: newScrollPositionID)
            }
            .onChange(of: selectedCardIndex.wrappedValue) { _, newSelectedCardIndex in
                updateScrollPositionIDIfNeeded(from: newSelectedCardIndex)
            }
            .task {
                withTransaction(Transaction(animation: nil)) {
                    scrollPositionID = Self.userWalletID(at: selectedCardIndex.wrappedValue, in: userWalletPageBuilders)
                }
            }
        }

        private var pagePosition: CGFloat {
            guard pageWidth > 0, let contentMinX else { return CGFloat(selectedCardIndex.wrappedValue) }
            return -contentMinX / pageWidth
        }

        private func contentMinX(in contentGeometryProxy: GeometryProxy) -> CGFloat {
            contentGeometryProxy.frame(in: .named(CoordinateSpaceIdentifier.horizontalScrollView)).minX
        }

        private func reportPagePositionIfPossible() {
            guard pageWidth > 0, contentMinX != nil else { return }
            onPagePositionChanged(pagePosition)
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
            userWalletPageBuilders[safe: index]?.id
        }
    }
}

extension MainHorizontalPagingScrollView {
    enum Paddings {
        static let contentFooterTop = CGFloat(40)
        static let contentFooterBottom = CGFloat(20)
    }

    private enum Sizes {
        static let navigationBalanceMaxYOffset = CGFloat(16)
        static let scrolledToTopTolerance: CGFloat = 0.5
    }

    private enum CoordinateSpaceIdentifier: Hashable {
        case horizontalScrollView
    }

    private struct ScrollAdjustedValues: Equatable {
        var didScrollToTop: Bool
        var navigationBarBalanceOpacity: CGFloat
        var navigationBarBalanceOffsetY: CGFloat
        var pagingIndicatorOpacity: CGFloat
        /// `nil` until `handlePagingIndicatorOffsetChanged` reports. `handleContentPropertiesChanged` writes the same
        /// struct and can land first — a placeholder zero here would park the indicator at the top of the screen.
        var pagingIndicatorBaseOffsetY: CGFloat?
        var dragRefreshControlHeight: CGFloat
        var backgroundOpacity: CGFloat
        var contentFooterOverlayIsVisible: Bool

        static let initial = ScrollAdjustedValues(
            didScrollToTop: true,
            navigationBarBalanceOpacity: 1,
            navigationBarBalanceOffsetY: 0,
            pagingIndicatorOpacity: 0,
            pagingIndicatorBaseOffsetY: nil,
            dragRefreshControlHeight: 0,
            backgroundOpacity: 1,
            contentFooterOverlayIsVisible: false
        )
    }
}
