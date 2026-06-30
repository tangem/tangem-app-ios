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

    @State private var settleTask: Task<Void, Never>?
    @State private var scrollEnableTask: Task<Void, Never>?

    /// [REDACTED_USERNAME] (not a stored `let`) so the engine survives the view's per-frame re-creations; being a class,
    /// mutating its phase/velocity doesn't invalidate the view.
    @State private var snapEngine = MagneticHeaderSnapEngine()

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
                    scrollDisabled: scrollDisabled,
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
                    .frame(minHeight: rootGeometryProxy.size.height + snapLayout.fullHeaderHeight, alignment: .top)
                    .onGeometryChange(
                        for: CGRect.self,
                        of: { contentGeometryProxy in
                            contentGeometryProxy.frame(in: .global)
                        },
                        action: { contentFrame in
                            handleScrollChanged(contentFrame, rootGeometryProxy, scrollProxy)
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
                        apply(snapEngine.dragBegan(), with: scrollProxy)
                    } else {
                        apply(snapEngine.dragEnded(), with: scrollProxy)
                    }
                }
                .onDisappear {
                    settleTask?.cancel()
                    scrollEnableTask?.cancel()
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

    private func handleScrollChanged(_ contentFrame: CGRect, _ rootGeometryProxy: GeometryProxy, _ scrollProxy: ScrollViewProxy) {
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

        // A snap animation drives the offset while scroll is disabled; feeding it back would corrupt velocity.
        if !scrollDisabled {
            let command = snapEngine.offsetChanged(contentOffsetY, at: CACurrentMediaTime(), layout: snapLayout)
            apply(command, with: scrollProxy)
        }

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

    private var snapLayout: MagneticHeaderSnapEngine.Layout {
        MagneticHeaderSnapEngine.Layout(
            safeAreaInsetsTop: containerGeometryProperties.safeAreaInsetsTop,
            fullHeaderHeight: Paddings.headerTop + headerHeight
        )
    }

    private func apply(_ command: MagneticHeaderSnapEngine.Command?, with scrollProxy: ScrollViewProxy) {
        switch command {
        case .snap(let anchor):
            snap(to: anchor, with: scrollProxy)
        case .scheduleSettle:
            scheduleSettle(with: scrollProxy)
        case .cancelSettle:
            settleTask?.cancel()
        case .none:
            break
        }
    }

    private func scheduleSettle(with scrollProxy: ScrollViewProxy) {
        settleTask?.cancel()
        settleTask = Task {
            try? await Task.sleep(for: .seconds(Durations.settleDebounce))
            guard !Task.isCancelled else { return }
            apply(snapEngine.settleFired(offsetY: contentOffsetY, layout: snapLayout), with: scrollProxy)
        }
    }

    private func snap(to anchor: MagneticHeaderSnapEngine.HeaderAnchor, with scrollProxy: ScrollViewProxy) {
        let targetID: HeaderScrollAnchorIdentifier = anchor == .bottom ? .bottom : .top

        // Disabling scroll halts in-flight deceleration so the spring starts from the current position.
        scrollDisabled = true
        FeedbackGenerator.selection()
        withAnimation(.spring(response: Durations.snapResponse, dampingFraction: Durations.snapDamping)) {
            scrollProxy.scrollTo(targetID, anchor: .top)
        }

        scrollEnableTask?.cancel()
        scrollEnableTask = Task {
            // snapResponse re-used as the re-enable delay: the spring keeps settling past it, but the phase
            // guard means the residual programmatic offsets never reach flick detection.
            try? await Task.sleep(for: .seconds(Durations.snapResponse))
            guard !Task.isCancelled else { return }
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
        static let settleDebounce = 0.15
        static let snapResponse = 0.25
        static let snapDamping = 0.85
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
        let scrollDisabled: Bool
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
                .scrollDisabled(scrollDisabled)
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
