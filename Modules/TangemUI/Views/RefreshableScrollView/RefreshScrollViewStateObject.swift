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

public class RefreshScrollViewStateObject: ObservableObject {
    @Published var state: RefreshState = .idle
    @Published var contentOffset: CGPoint = .zero
    @Published var refreshingPadding: CGFloat = .zero {
        didSet { print("refreshingPadding ->>", refreshingPadding) }
    }

    var progress: CGFloat {
        clamp(-contentOffset.y.rounded() / settings.threshold, min: 0, max: 1)
    }

    lazy var scrollViewDelegate = DraggingScrollViewDelegate(
        willEndDraggingAt: { [weak self] targetOffset in
            self?.targetContentOffset(draggingWillEndAt: targetOffset)
        }
    )

    let settings: Settings
    private var refreshable: () async -> Void

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
            Task {
                await self?.refreshable()
                await self?.stopRefreshing()
            }
        }

        state = .refreshing(refreshing)
    }

    @MainActor
    func stopRefreshing() {
        print("Stop refreshing at", contentOffset)

        // Decide according on the current content offset
        switch contentOffset.y.rounded(.down) {
        // Still dragging. The `refreshingPadding` will be update after dragging is end
        case _ where scrollViewDelegate.dragging:
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
        case .idle where offset.y < -settings.threshold:
            print("Start refreshing")
            startRefreshing()
        case .stillDragging where !scrollViewDelegate.dragging && offset.y.rounded(.down) >= .zero:
            state = .idle
            print("Come back to idle state after stillDragging")
        default:
            break
        }
    }

    func targetContentOffset(draggingWillEndAt targetOffset: CGPoint) -> DraggingScrollViewDelegate.TargetContentOffset? {
        let targetOffsetInsideRefreshArea: Bool = (0 ... refreshingPadding).contains(targetOffset.y.rounded(.down))
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

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1, execute: done)
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

    struct Settings {
        public let refreshAreaHeight: CGFloat
        public let thresholdMultiplier: CGFloat

        public init(refreshAreaHeight: CGFloat = 75, thresholdMultiplier: CGFloat = 1.5) {
            self.refreshAreaHeight = refreshAreaHeight
            self.thresholdMultiplier = thresholdMultiplier
        }

        public var threshold: CGFloat { refreshAreaHeight * thresholdMultiplier }
    }
}

final class DraggingScrollViewDelegate: NSObject, UIScrollViewDelegate {
    private let willEndDraggingAt: (CGPoint) -> TargetContentOffset?

    private weak var scrollView: UIScrollView?

    /// We can't use UIScrollView.isDragging here
    /// Because it's still true while scroll view is decelerating
    private(set) var dragging: Bool = false

    init(willEndDraggingAt: @escaping (CGPoint) -> TargetContentOffset?) {
        self.willEndDraggingAt = willEndDraggingAt
    }

    func set(scrollView: UIScrollView?) {
        self.scrollView = scrollView
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
        dragging = true
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        dragging = false
        let topInset = topInset(scrollView: scrollView)

        let y = targetContentOffset.pointee.y + topInset
        let point = CGPoint(x: targetContentOffset.pointee.x, y: y)

        print("scrollViewWillEndDragging: \(point)")
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

    enum TargetContentOffset {
        case top
    }

    private func topInset(scrollView: UIScrollView) -> CGFloat {
        if #available(iOS 17.0, *) {
            scrollView.safeAreaInsets.top
        } else {
            scrollView.contentInset.top
        }
    }
}
