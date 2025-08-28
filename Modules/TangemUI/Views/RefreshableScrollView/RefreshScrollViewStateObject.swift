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
    private let refreshable: () async -> Void

    private var bag = Set<AnyCancellable>()

    public init(settings: Settings = .init(), refreshable: @escaping () async -> Void) {
        self.settings = settings
        self.refreshable = refreshable

        bind()
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
        case .stillDragging where !scrollViewDelegate.dragging && offset.y.rounded() >= .zero:
            state = .idle
            print("Come back to idle state after stillDragging")
        default:
            break
        }
    }

    func targetContentOffset(draggingWillEndAt targetOffset: CGPoint) -> DraggingScrollViewDelegate.TargetContentOffset? {
        let targetOffsetInsideRefreshArea: Bool = (0 ... refreshingPadding).contains(targetOffset.y)
        let refreshingPaddingIsOpen = refreshingPadding > 0

        switch state {
        case .refreshing where !refreshingPaddingIsOpen:
            onRefreshingPadding()
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

    func onRefreshingPadding() {
        // Extreme easyOut animation
        // .timingCurve(0, 0.5, 0.5, 1, duration: 0.3)
        withAnimation(.easeOut(duration: 0.2)) {
            refreshingPadding = settings.refreshAreaHeight
        }
    }

    func offRefreshingPadding() {
        let shouldScrollToTop = (1 ... refreshingPadding).contains(contentOffset.y)
        withAnimation(.easeOut(duration: 0.2)) {
            refreshingPadding = .zero
        }

        if shouldScrollToTop {
            scrollViewDelegate.scrollToTop()
        }
    }

    // MARK: - Start / Stop refreshing

    func startRefreshing() {
        FeedbackGenerator.heavy()

        let task = Task {
            await refreshable()
            await stopRefreshing()
        }

        state = .refreshing(task)
    }

    @MainActor
    func stopRefreshing() {
        print("Stop refreshing at", contentOffset)

        // Decide according on the current content offset
        switch contentOffset.y.rounded() {
        // Still dragging. The `refreshingPadding` will be update after dragging is end
        case _ where scrollViewDelegate.dragging:
            state = .stillDragging

        // Stop on the top area
        case 0 ... refreshingPadding:
            state = .idle
            offRefreshingPadding()

        // Somewhere is the middle of content
        default:
            state = .idle
        }
    }
}

public extension RefreshScrollViewStateObject {
    enum RefreshState: Hashable {
        case idle
        case refreshing(_ task: Task<Void, Never>)
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

        let top = CGPoint(x: scrollView.safeAreaInsets.left, y: -scrollView.safeAreaInsets.top)
        UIView.animate(withDuration: 0.2) {
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

        let y = targetContentOffset.pointee.y + scrollView.safeAreaInsets.top
        let point = CGPoint(x: targetContentOffset.pointee.x, y: y)

        print("scrollViewWillEndDragging: \(point)")
        switch willEndDraggingAt(point) {
        case .none:
            break
        case .top:
            targetContentOffset.pointee = .init(
                x: targetContentOffset.pointee.x,
                y: -scrollView.safeAreaInsets.top
            )
        }
    }

    enum TargetContentOffset {
        case top
    }
}
