//
//  RefreshScrollViewStateObject.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUIUtils
import TangemFoundation
import TangemLogger

public class RefreshScrollViewStateObject: ObservableObject {
    @Published var state: RefreshState = .idle
    @Published var contentOffset: CGPoint = .zero
    @Published var refreshingPadding: CGFloat = .zero

    var draggingStartFromTop: Bool {
        guard let dragging = scrollViewDelegate.dragging else {
            return false
        }

        // If user start dragging from the top area then possible to start refresh
        // Exclude refresh starting when user made a heavy scroll from the middle of list
        return (0 ... settings.refreshAreaHeight).contains(-dragging.startOffset.y.rounded())
    }

    lazy var scrollViewDelegate = DraggingScrollViewDelegate(
        willEndDraggingAt: { [weak self] targetOffset in
            self?.targetContentOffset(draggingWillEndAt: targetOffset)
        }
    )

    let settings: Settings
    private var refreshable: () async -> Void

    private var refreshTask: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

    public init(settings: Settings = .init(), refreshable: @escaping () async -> Void) {
        self.settings = settings
        self.refreshable = refreshable

        bind()
    }

    // MARK: - Start / Stop refreshing

    func startRefreshing() {
        FeedbackGenerator.heavy()

        // Clouser which start refresh
        let refreshing: () -> Void = { [weak self] in
            switch self?.settings.refreshTaskTimeout {
            case .some(let timeout):
                runTask(
                    withTimeout: timeout,
                    code: { await self?.refreshing() },
                    onTimeout: {
                        ConsoleLog.error(error: Error.timeout)
                        Task { @MainActor in self?.stopRefreshing() }
                    }
                )

            case .none:
                Task { await self?.refreshing() }
            }
        }

        state = .refreshing(refreshing)
    }

    func refreshing() async {
        await refreshable()
        try? await Task.sleep(seconds: settings.stopRefreshingDelay)
        await stopRefreshing()
    }

    @MainActor
    func stopRefreshing() {
        // Decide according on the current content offset
        switch contentOffset.y.rounded() {
        // Still dragging. The `refreshingPadding` will be update after dragging is end
        case _ where scrollViewDelegate.dragging != nil:
            state = .stillDragging

        // Stop on the top area
        case ...refreshingPadding:
            state = .idle
            offRefreshingPadding()

        // Somewhere is the middle of content
        default:
            state = .idle
        }
    }

    // MARK: - Offset handling

    func bind() {
        $contentOffset
            .withWeakCaptureOf(self)
            .sink { $0.didChange(offset: $1) }
            .store(in: &bag)
    }

    func didChange(offset: CGPoint) {
        switch state {
        case .idle where draggingStartFromTop && offset.y.rounded() < -settings.threshold:
            startRefreshing()
        case .stillDragging where scrollViewDelegate.dragging == nil && offset.y.rounded() >= .zero:
            state = .idle
        default:
            break
        }
    }

    func targetContentOffset(draggingWillEndAt targetOffset: CGPoint) -> DraggingScrollViewDelegate.TargetContentOffset? {
        let targetOffsetInsideRefreshArea: Bool = (0 ... refreshingPadding).contains(targetOffset.y.rounded())
        let refreshingPaddingIsOpen = refreshingPadding > 0

        switch state {
        case .refreshing(let refresh) where !refreshingPaddingIsOpen:
            onRefreshingPadding(done: refresh)
            return .top

        case .idle where refreshingPaddingIsOpen && targetOffsetInsideRefreshArea,
             .stillDragging where refreshingPaddingIsOpen && targetOffsetInsideRefreshArea:
            offRefreshingPadding()
            return .top

        default:
            return .none
        }
    }

    // MARK: - Refreshing Padding

    func onRefreshingPadding(done: @escaping () -> Void) {
        guard refreshingPadding.isZero else {
            return
        }

        let duration: CGFloat = 0.3
        // Extreme easeOut animation
        let animation = Animation.timingCurve(0, 0.5, 0.5, 1, duration: duration)
        withAnimation(animation) {
            refreshingPadding = settings.refreshAreaHeight
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + settings.startRefreshingDelay, execute: done)
    }

    func offRefreshingPadding() {
        guard !refreshingPadding.isZero else {
            return
        }

        let shouldScrollToTop = (1 ... refreshingPadding).contains(contentOffset.y)
        withAnimation(.easeOut(duration: 0.4)) {
            refreshingPadding = .zero
        }

        if shouldScrollToTop {
            scrollViewDelegate.scrollToTop()
        }
    }
}

public extension RefreshScrollViewStateObject {
    enum RefreshState {
        case idle
        case refreshing(_ task: () -> Void)
        case stillDragging
    }

    enum Error: LocalizedError {
        case timeout

        public var errorDescription: String? {
            switch self {
            case .timeout: "Stop refreshing by timeout"
            }
        }
    }

    /// Ideally, after the redesign, we will have an empty header in the main section
    /// and we won't have to add padding at the top, which causes a lot of unsmooth animation.
    struct Settings {
        public let refreshAreaHeight: CGFloat
        public let thresholdMultiplier: CGFloat
        public let startRefreshingDelay: TimeInterval
        public let stopRefreshingDelay: TimeInterval
        public let refreshTaskTimeout: TimeInterval?

        public init(
            refreshAreaHeight: CGFloat = 75,
            thresholdMultiplier: CGFloat = 2,
            startRefreshingDelay: TimeInterval = 0.1,
            stopRefreshingDelay: TimeInterval = 1,
            refreshTaskTimeout: TimeInterval? = nil
        ) {
            self.refreshAreaHeight = refreshAreaHeight
            self.thresholdMultiplier = thresholdMultiplier
            self.startRefreshingDelay = startRefreshingDelay
            self.stopRefreshingDelay = stopRefreshingDelay
            self.refreshTaskTimeout = refreshTaskTimeout
        }

        public var threshold: CGFloat { refreshAreaHeight * thresholdMultiplier }
    }
}

final class DraggingScrollViewDelegate: NSObject, UIScrollViewDelegate {
    private let willEndDraggingAt: (CGPoint) -> TargetContentOffset?

    private weak var scrollView: UIScrollView?
    private weak var internalScrollViewDelegate: UIScrollViewDelegate?

    /// We can't use UIScrollView.isDragging here
    /// Because it's still true while scroll view is decelerating
    private(set) var dragging: Dragging?

    init(willEndDraggingAt: @escaping (CGPoint) -> TargetContentOffset?) {
        self.willEndDraggingAt = willEndDraggingAt
    }

    func set(scrollView: UIScrollView?) {
        // Do not double the set
        guard self.scrollView == nil else {
            return
        }

        self.scrollView = scrollView
        internalScrollViewDelegate = scrollView?.delegate

        scrollView?.delegate = self
    }

    func scrollToTop() {
        guard let scrollView else {
            assertionFailure("UIScrollView isn't set")
            return
        }

        let topInset = topInset(scrollView: scrollView)
        let top = CGPoint(x: scrollView.safeAreaInsets.left, y: -topInset)
        UIView.animate(withDuration: 0.4) {
            scrollView.setContentOffset(top, animated: false)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)

        dragging = .init(
            startOffset: .init(
                x: scrollView.contentOffset.x,
                y: scrollView.contentOffset.y + topInset(scrollView: scrollView)
            )
        )
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        internalScrollViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)

        dragging = nil
        let topInset = topInset(scrollView: scrollView)

        let y = targetContentOffset.pointee.y + topInset
        let point = CGPoint(x: targetContentOffset.pointee.x, y: y)

        switch willEndDraggingAt(point) {
        case .none:
            break
        case .top:
            targetContentOffset.pointee = .init(
                x: targetContentOffset.pointee.x,
                y: -topInset
            )
        }
    }

    private func topInset(scrollView: UIScrollView) -> CGFloat {
        if #available(iOS 17.0, *) {
            scrollView.safeAreaInsets.top
        } else {
            scrollView.contentInset.top
        }
    }

    enum TargetContentOffset {
        case top
    }

    struct Dragging {
        let startOffset: CGPoint
    }
}

// MARK: - Proxy methods

extension DraggingScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewDidZoom?(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        internalScrollViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        internalScrollViewDelegate?.viewForZooming?(in: scrollView)
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        internalScrollViewDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        internalScrollViewDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        internalScrollViewDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewDidScrollToTop?(scrollView)
    }

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        internalScrollViewDelegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}
