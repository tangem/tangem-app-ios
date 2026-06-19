//
//  UserWalletView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import func TangemFoundation.clamp
import enum TangemFoundation.FeedbackGenerator
import TangemUI
import TangemAccessibilityIdentifiers

struct UserWalletView: View {
    let pageBuilder: MainUserWalletPageBuilder
    let showPagingIndicatorStub: Bool
    let onContentPropertiesChanged: (ScrollContentProperties) -> Void
    let onNormalizedOffsetYChanged: (CGFloat, Animation?) -> Void
    let containerGeometryProperties: ContainerGeometryProperties

    @State private var scrollDisabled = false
    @State private var contentOffsetY = CGFloat.zero
    @State private var normalizedOffsetY = CGFloat.zero
    @State private var headerHeight = CGFloat.zero
    @State private var headerScale: CGFloat = 1
    @State private var headerOpacity: CGFloat = 1

    @ScaledMetric private var headerBalanceTextHeight = CGFloat.unit(.x12)
    @ScaledMetric private var headerSubtitleHeight = CGFloat.unit(.x7)

    @State private var headerAutoScrollTask: Task<Void, Never>?

    private let pullToRefreshAction: @MainActor () async -> Void
    @EnvironmentObject private var scrollDetector: ScrollDetector

    init(
        pageBuilder: MainUserWalletPageBuilder,
        showPagingIndicatorStub: Bool,
        pullToRefreshAction: @MainActor @escaping () async -> Void,
        onContentPropertiesChanged: @escaping (ScrollContentProperties) -> Void,
        onNormalizedOffsetYChanged: @escaping (CGFloat, Animation?) -> Void,
        containerGeometryProperties: ContainerGeometryProperties
    ) {
        self.pageBuilder = pageBuilder
        self.showPagingIndicatorStub = showPagingIndicatorStub
        self.onContentPropertiesChanged = onContentPropertiesChanged
        self.onNormalizedOffsetYChanged = onNormalizedOffsetYChanged
        self.containerGeometryProperties = containerGeometryProperties

        self.pullToRefreshAction = pullToRefreshAction
    }

    var body: some View {
        GeometryReader { rootGeometryProxy in
            ScrollViewReader { scrollProxy in
                RefreshableScrollView(
                    axes: .vertical,
                    onNormalizedOffsetYChanged: handleNormalizedOffsetYChanged,
                    refreshAction: pullToRefreshAction,
                ) {
                    VStack(spacing: .zero) {
                        headerTopAnchorSpacer
                        header
                        headerBottomAnchorSpacer
                        content
                        contentFooterSpacer
                        bottomOverlaySpacer
                    }
                    .scrollDisabled(scrollDisabled)
                    .onGeometryChange(
                        for: CGRect.self,
                        of: { contentGeometryProxy in
                            contentGeometryProxy.frame(in: .global)
                        },
                        action: { contentFrame in
                            handleScrollChanged(contentFrame, rootGeometryProxy)
                        }
                    )
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabledBackport()
                .scrollBounceBehavior(.always)
                .onChange(of: scrollDetector.isScrolling) { [wasScrolling = scrollDetector.isScrolling] isScrolling in
                    guard wasScrolling != isScrolling else {
                        return
                    }

                    if isScrolling {
                        cancelAutoScrollTask()
                    } else {
                        scheduleAutoScrollTask(with: scrollProxy)
                    }
                }
            }
        }
    }

    private var headerTopAnchorSpacer: some View {
        Spacer(minLength: .zero)
            .frame(height: Paddings.headerTop)
            .id(HeaderScrollAnchorIdentifier.top)
    }

    private var header: some View {
        MainUserWalletHeader(
            headerViewModel: pageBuilder.headerModel,
            actionButtonsViewModel: pageBuilder.actionButtonsViewModel,
            showPagingIndicatorStub: showPagingIndicatorStub,
        )
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { headerHeight in
            self.headerHeight = headerHeight
        }
        .scaleEffect(headerScale)
        .opacity(headerOpacity)
    }

    private var headerBottomAnchorSpacer: some View {
        Spacer(minLength: .zero)
            .frame(height: Paddings.headerBottom)
            .id(HeaderScrollAnchorIdentifier.bottom)
    }

    private var content: some View {
        pageBuilder.content
            // Contain banner carousels within the page: the pager disables scroll clipping for the header fade.
            .clipped()
    }

    private var contentFooterSpacer: some View {
        Spacer(minLength: .zero)
            .frame(height: containerGeometryProperties.contentFooterHeight)
    }

    private var bottomOverlaySpacer: some View {
        Spacer(minLength: .zero)
            .frame(height: containerGeometryProperties.bottomOverlayHeight)
    }

    private func handleScrollChanged(_ contentFrame: CGRect, _ rootGeometryProxy: GeometryProxy) {
        let scrollViewFrameHeight = rootGeometryProxy.size.height
        let contentOffsetY = contentFrame.minY

        let contentFooterBottomPadding = MainHorizontalPagingScrollView.Paddings.contentFooterBottom
        let didScrollToBottom = contentFrame.maxY
            - containerGeometryProperties.bottomOverlayHeight
            - contentFooterBottomPadding
            <= scrollViewFrameHeight

        let startY = containerGeometryProperties.safeAreaInsetsTop
        let endY = headerBalanceTextHeight + Paddings.headerTop
        let progress = clamp((startY - contentOffsetY) / (startY + endY), min: 0, max: 1)
        let headerOpacity = headerOpacity(for: progress)

        self.contentOffsetY = contentOffsetY

        self.headerOpacity = headerOpacity
        headerScale = headerScale(for: progress)

        let contentProperties = ScrollContentProperties(
            contentOffsetY: contentOffsetY,
            pagingIndicatorOpacity: headerOpacity,
            didScrollToBottom: didScrollToBottom
        )

        onContentPropertiesChanged(contentProperties)
    }

    func handleNormalizedOffsetYChanged(_ normalizedOffsetY: CGFloat, _ animation: Animation?) {
        let pagingIndicatorOffsetY = normalizedOffsetY
            + Paddings.headerTop
            + headerBalanceTextHeight
            + MainUserWalletHeader.Paddings.balanceBottom
            + headerSubtitleHeight
            + MainUserWalletHeader.Paddings.subtitleBottom

        onNormalizedOffsetYChanged(pagingIndicatorOffsetY, animation)
    }

    private func cancelAutoScrollTask() {
        headerAutoScrollTask?.cancel()
        headerAutoScrollTask = nil
    }

    private func scheduleAutoScrollTask(with scrollViewProxy: ScrollViewProxy) {
        headerAutoScrollTask = Task {
            try? await Task.sleep(for: .seconds(Durations.headerAutoScrollDebounce))

            guard !Task.isCancelled else { return }

            performHeaderAutoScrollIfNeeded(with: scrollViewProxy)
            headerAutoScrollTask = nil
        }
    }

    private func performHeaderAutoScrollIfNeeded(with scrollViewProxy: ScrollViewProxy) {
        let safeAreaInsetsTop = containerGeometryProperties.safeAreaInsetsTop
        let fullHeaderHeight = Paddings.headerTop + headerHeight
        let headerMaxY = contentOffsetY + fullHeaderHeight

        let screenTopIsBelowHeaderTop = safeAreaInsetsTop > contentOffsetY
        let screenTopIsAboveHeaderBottom = safeAreaInsetsTop < headerMaxY

        guard screenTopIsBelowHeaderTop, screenTopIsAboveHeaderBottom else {
            return
        }

        let hasReachedMiddlePoint = (safeAreaInsetsTop - contentOffsetY) > fullHeaderHeight / 2
        let targetID: HeaderScrollAnchorIdentifier = hasReachedMiddlePoint ? .bottom : .top

        scrollDisabled = true
        withAnimation(.spring(duration: Durations.headerAutoScrollAnimation)) {
            scrollViewProxy.scrollTo(targetID, anchor: .top)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Durations.headerAutoScrollAnimation) {
            scrollDisabled = false
        }
    }

    private func headerOpacity(for progress: CGFloat) -> CGFloat {
        1 - progress * 0.8
    }

    private func headerScale(for progress: CGFloat) -> CGFloat {
        1 - progress * 0.1
    }
}

extension UserWalletView {
    struct ScrollContentProperties: Equatable {
        let contentOffsetY: CGFloat
        let pagingIndicatorOpacity: CGFloat
        let didScrollToBottom: Bool
    }

    struct ContainerGeometryProperties: Equatable {
        let safeAreaInsetsTop: CGFloat
        let bottomOverlayHeight: CGFloat
        let contentFooterHeight: CGFloat
    }

    private enum Paddings {
        static let headerTop = CGFloat.unit(.x13)
        static let headerBottom = CGFloat.unit(.x3)
    }

    private enum Durations {
        static let headerAutoScrollDebounce = 0.5
        static let headerAutoScrollAnimation = 0.3
    }

    private enum HeaderScrollAnchorIdentifier: Hashable {
        case top
        case bottom
    }

    private enum RefreshableConstants {
        static let coordinateSpaceName = "UserWalletView.RefreshableScrollView"
        static let refreshTaskDebugName = "UserWalletView.RefreshableScrollView"
        static let activeRefreshControlMaxHeight: CGFloat = 70
        static let contentOffsetThresholdTrigger: CGFloat = 130
    }
}

extension UserWalletView {
    private struct RefreshableScrollView<Content: View>: View {
        let axes: Axis.Set
        let onNormalizedOffsetYChanged: (CGFloat, Animation?) -> Void
        let refreshAction: @MainActor () async -> Void
        @ViewBuilder let content: Content

        @State private var contentOffsetY = CGFloat.zero
        @State private var refreshOffsetProgress = CGFloat.zero

        @State private var canStartNewRefresh = true
        @State private var refreshTask: Task<Void, Never>?

        var body: some View {
            ZStack(alignment: .top) {
                progressView

                ScrollView(axes) {
                    VStack(spacing: .zero) {
                        Rectangle()
                            .fill(.clear)
                            .frame(height: refreshIndicatorHeight)

                        // [REDACTED_TODO_COMMENT]
                        content
                    }
                    .onGeometryChange(
                        for: CGFloat.self,
                        of: { proxy in
                            proxy.frame(in: .named(RefreshableConstants.coordinateSpaceName)).minY
                        },
                        action: { contentOffsetY in
                            self.contentOffsetY = contentOffsetY

                            if contentOffsetY > RefreshableConstants.contentOffsetThresholdTrigger {
                                startRefreshingIfNeeded()
                            }

                            if refreshTask == nil, !canStartNewRefresh {
                                canStartNewRefresh = contentOffsetY <= 0
                            }

                            onNormalizedOffsetYChanged(contentOffsetY + refreshIndicatorHeight, nil)
                        }
                    )
                }
                .coordinateSpace(name: RefreshableConstants.coordinateSpaceName)
            }
        }

        private func startRefreshingIfNeeded() {
            guard canStartNewRefresh else {
                return
            }

            canStartNewRefresh = false

            FeedbackGenerator.heavy()
            refreshTask = Task(name: RefreshableConstants.refreshTaskDebugName) {
                await refreshAction()

                let animation = Animation.easeInOut(duration: 0.25)
                withAnimation(animation) {
                    refreshTask = nil
                    canStartNewRefresh = contentOffsetY <= 0
                    onNormalizedOffsetYChanged(contentOffsetY + refreshIndicatorHeight, animation)
                }
            }
        }

        private var refreshIndicatorHeight: CGFloat {
            if refreshTask != nil {
                return RefreshableConstants.activeRefreshControlMaxHeight
            }

            let progress = max(0, min(1.0, contentOffsetY / RefreshableConstants.contentOffsetThresholdTrigger))
            return progress * RefreshableConstants.activeRefreshControlMaxHeight
        }

        private var progressView: some View {
            PetalProgressView(
                mode: refreshTask == nil
                    ? .progress(refreshIndicatorHeight / RefreshableConstants.activeRefreshControlMaxHeight)
                    : .spinning
            )
            .opacity(contentOffsetY < -refreshIndicatorHeight ? 0 : 1)
            .padding(.top, 20)
            .accessibilityIdentifier(refreshTask == nil ? MainAccessibilityIdentifiers.refreshStateIdle : MainAccessibilityIdentifiers.refreshStateRefreshing)
        }
    }
}
