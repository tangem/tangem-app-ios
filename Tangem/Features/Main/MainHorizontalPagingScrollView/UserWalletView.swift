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
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct UserWalletView: View {
    let pageBuilder: MainUserWalletPageBuilder
    let showPagingIndicatorStub: Bool
    let isRefreshing: Bool
    let onContentPropertiesChanged: (ScrollContentProperties) -> Void
    let onPagingIndicatorOffsetChanged: (PagingIndicatorOffset) -> Void
    let containerGeometryProperties: ContainerGeometryProperties

    @State private var scrollDisabled = false
    @State private var contentOffsetY = CGFloat.zero
    @State private var headerHeight = CGFloat.zero
    @State private var headerScale: CGFloat = 1
    @State private var headerOpacity: CGFloat = 1

    @ScaledMetric private var headerBalanceTextHeight = CGFloat(48)
    @ScaledMetric private var headerSubtitleHeight = CGFloat(28)

    @State private var settleTask: Task<Void, Never>?
    @State private var scrollEnableTask: Task<Void, Never>?

    /// [REDACTED_USERNAME] (not a stored `let`) so the engine survives the view's per-frame re-creations; being a class,
    /// mutating its phase/velocity doesn't invalidate the view.
    @State private var snapEngine = MagneticHeaderSnapEngine()

    private let pullToRefreshAction: @MainActor () -> Void
    @EnvironmentObject private var scrollDetector: ScrollDetector

    init(
        pageBuilder: MainUserWalletPageBuilder,
        showPagingIndicatorStub: Bool,
        isRefreshing: Bool,
        pullToRefreshAction: @MainActor @escaping () -> Void,
        onContentPropertiesChanged: @escaping (ScrollContentProperties) -> Void,
        onPagingIndicatorOffsetChanged: @escaping (PagingIndicatorOffset) -> Void,
        containerGeometryProperties: ContainerGeometryProperties
    ) {
        self.pageBuilder = pageBuilder
        self.showPagingIndicatorStub = showPagingIndicatorStub
        self.isRefreshing = isRefreshing
        self.onContentPropertiesChanged = onContentPropertiesChanged
        self.onPagingIndicatorOffsetChanged = onPagingIndicatorOffsetChanged
        self.containerGeometryProperties = containerGeometryProperties

        self.pullToRefreshAction = pullToRefreshAction
    }

    var body: some View {
        GeometryReader { rootGeometryProxy in
            ScrollViewReader { scrollProxy in
                RefreshableScrollView(
                    axes: .vertical,
                    scrollDisabled: scrollDisabled,
                    isRefreshing: isRefreshing,
                    onScrollOffsetChanged: handleScrollOffsetChanged,
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
        .verticalBarSafeAreaPadding(containerGeometryProperties.verticalBarInsets)
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

    /// Reports where the paging indicator belongs on this page: the geometry the page measures itself, plus the drag,
    /// but never the height of an *active* refresh control. The pager owns the refresh state and adds that part.
    private func handleScrollOffsetChanged(_ contentOffsetY: CGFloat, _ dragRefreshControlHeight: CGFloat) {
        let baseOffsetY = contentOffsetY
            + Paddings.headerTop
            + headerBalanceTextHeight
            + MainUserWalletHeader.Paddings.balanceBottom
            + headerSubtitleHeight
            + MainUserWalletHeader.Paddings.subtitleBottom

        onPagingIndicatorOffsetChanged(
            PagingIndicatorOffset(baseOffsetY: baseOffsetY, dragRefreshControlHeight: dragRefreshControlHeight)
        )
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

    struct PagingIndicatorOffset {
        /// Where the paging indicator sits within the page before the refresh control is added: the page's own
        /// scroll offset plus the header above the indicator.
        let baseOffsetY: CGFloat
        /// Height the refresh control has from the drag alone, i.e. as if no refresh were running.
        let dragRefreshControlHeight: CGFloat
    }

    struct ContainerGeometryProperties: Equatable {
        let safeAreaInsetsTop: CGFloat
        let bottomOverlayHeight: CGFloat
        let contentFooterHeight: CGFloat
        let verticalBarInsets: EdgeInsets
    }

    private enum Paddings {
        static let headerTop = CGFloat(52)
        static let headerBottom = CGFloat(12)
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

    enum RefreshableConstants {
        static let coordinateSpaceName = "UserWalletView.RefreshableScrollView"
        static let activeRefreshControlMaxHeight: CGFloat = 70
        static let contentOffsetThresholdTrigger: CGFloat = 130
        static let refreshEndAnimation = Animation.easeInOut(duration: 0.25)

        static func dragRefreshControlHeight(contentOffsetY: CGFloat) -> CGFloat {
            clamp(contentOffsetY / contentOffsetThresholdTrigger, min: 0, max: 1) * activeRefreshControlMaxHeight
        }

        /// Shared by the page, which lays the control out, and by the pager, which places the paging indicator over it.
        static func refreshControlHeight(isRefreshing: Bool, dragRefreshControlHeight: CGFloat) -> CGFloat {
            max(dragRefreshControlHeight, isRefreshing ? activeRefreshControlMaxHeight : .zero)
        }
    }
}

extension UserWalletView {
    private struct RefreshableScrollView<Content: View>: View {
        let axes: Axis.Set
        let scrollDisabled: Bool
        /// Owned by `MainViewModel`, not by this view: a page is torn down and rebuilt while its refresh runs.
        let isRefreshing: Bool
        let onScrollOffsetChanged: (CGFloat, CGFloat) -> Void
        let refreshAction: @MainActor () -> Void
        @ViewBuilder let content: Content

        @State private var contentOffsetY = CGFloat.zero

        /// Transient gesture state, armed only once the content reports that it is at the top. Below iOS 17 a page
        /// whose refresh ends under a held finger is rebuilt while still pulled down, and must not refresh again
        /// right away.
        @State private var canStartNewRefresh = false

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

                            if !isRefreshing, !canStartNewRefresh {
                                canStartNewRefresh = contentOffsetY <= 0
                            }

                            onScrollOffsetChanged(contentOffsetY, dragRefreshControlHeight)
                        }
                    )
                    .modifyView { view in
                        if #unavailable(iOS 17.0) {
                            view
                                .clipToBoundsDisableBackport()
                                .task {
                                    onScrollOffsetChanged(0, 0)
                                }
                        } else {
                            view
                        }
                    }
                }
                .scrollDisabled(scrollDisabled)
                .coordinateSpace(name: RefreshableConstants.coordinateSpaceName)
            }
            // Collapses the refresh control when the refresh ends. Fires only on that flip, not on every drag frame.
            .animation(RefreshableConstants.refreshEndAnimation, value: isRefreshing)
            .onChange(of: isRefreshing) { isRefreshing in
                guard !isRefreshing else { return }

                canStartNewRefresh = contentOffsetY <= 0
            }
        }

        private func startRefreshingIfNeeded() {
            guard canStartNewRefresh, !isRefreshing else {
                return
            }

            canStartNewRefresh = false

            FeedbackGenerator.heavy()
            refreshAction()
        }

        private var dragRefreshControlHeight: CGFloat {
            RefreshableConstants.dragRefreshControlHeight(contentOffsetY: contentOffsetY)
        }

        private var refreshIndicatorHeight: CGFloat {
            RefreshableConstants.refreshControlHeight(
                isRefreshing: isRefreshing,
                dragRefreshControlHeight: dragRefreshControlHeight
            )
        }

        private var progressView: some View {
            PetalProgressView(
                mode: isRefreshing
                    ? .spinning
                    : .progress(refreshIndicatorHeight / RefreshableConstants.activeRefreshControlMaxHeight)
            )
            .opacity(contentOffsetY < -refreshIndicatorHeight ? 0 : 1)
            .padding(.top, 20)
            .accessibilityIdentifier(isRefreshing ? MainAccessibilityIdentifiers.refreshStateRefreshing : MainAccessibilityIdentifiers.refreshStateIdle)
        }
    }
}

// MARK: - iOS 16 ScrollView clip backport

@available(iOS, obsoleted: 17.0, message: "Remove this extension and related types entirely.")
private extension View {
    func clipToBoundsDisableBackport() -> some View {
        background(
            ClipToBoundsDisabler()
                .frame(width: .zero, height: .zero)
                .accessibilityHidden(true)
        )
    }
}

private struct ClipToBoundsDisabler: UIViewRepresentable {
    func makeUIView(context: Context) -> OnWindowAttachView {
        let view = OnWindowAttachView()
        // [REDACTED_USERNAME], SwiftUIIntrospect's traversal fails inside UIHostingConfiguration — see MainHorizontalPagingScrollView+Backport.swift.
        view.onAttachToWindow = { $0.enclosingScrollViews.first?.clipsToBounds = false }
        return view
    }

    func updateUIView(_ uiView: OnWindowAttachView, context: Context) {}
}
