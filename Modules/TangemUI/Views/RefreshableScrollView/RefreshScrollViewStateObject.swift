//
//  RefreshScrollViewStateObject.swift
//  TangemUI
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
    @Published var refreshControlStateObject: CustomRefreshControlStateObject
    @Published var refreshingPadding: CGFloat = .zero

    var contentOffset: CGPoint = .zero {
        didSet { didChange(offset: contentOffset) }
    }

    private let stateSubject = PassthroughSubject<RefreshState, Never>()

    public var statePublisher: AnyPublisher<RefreshState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var draggingStartFromTop: Bool {
        guard let dragging = scrollViewDelegate.dragging else {
            return false
        }

        // If user start dragging from the top area then possible to start refresh
        // Exclude refresh starting when user made a heavy scroll from the middle of list
        return (0 ... settings.refreshAreaHeight).contains(-dragging.startOffset.y.rounded())
    }

    lazy var scrollViewDelegate = RefreshScrollViewDelegate(
        willEndDraggingAt: { [weak self] targetOffset in
            self?.targetContentOffset(draggingWillEndAt: targetOffset)
        }
    )

    private let settings: Settings
    private var refreshable: () async -> Void

    private var state: RefreshState = .idle {
        didSet {
            stateSubject.send(state)
            refreshControlStateObject.update(state: state)
        }
    }

    public init(settings: Settings = .init(), refreshable: @escaping () async -> Void) {
        self.settings = settings
        self.refreshable = refreshable

        refreshControlStateObject = .init(settings: settings)
    }
}

// MARK: - Private

private extension RefreshScrollViewStateObject {
    // MARK: - Start / Stop refreshing

    func startRefreshing() {
        FeedbackGenerator.heavy()
        state = .willStartRefreshing

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
        try? await Task.sleep(for: .seconds(settings.stopRefreshingDelay))
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
            unsetRefreshingPadding()

        // Somewhere is the middle of content
        default:
            state = .idle
        }
    }

    // MARK: - Offset handling

    func didChange(offset: CGPoint) {
        refreshControlStateObject.update(offset: offset)

        switch state {
        case .idle where draggingStartFromTop && offset.y.rounded() < -settings.threshold:
            startRefreshing()
        case .stillDragging where scrollViewDelegate.dragging == nil && offset.y.rounded() >= .zero:
            state = .idle
        default:
            break
        }
    }

    func targetContentOffset(draggingWillEndAt targetOffset: CGPoint) -> RefreshScrollViewDelegate.TargetContentOffset? {
        let targetOffsetInsideRefreshArea: Bool = (0 ... refreshingPadding).contains(targetOffset.y.rounded())
        let refreshingPaddingIsOpen = refreshingPadding > 0

        switch state {
        case .refreshing(let refresh) where !refreshingPaddingIsOpen:
            setRefreshingPadding(done: refresh)
            return .top

        case .idle where refreshingPaddingIsOpen && targetOffsetInsideRefreshArea,
             .stillDragging where refreshingPaddingIsOpen && targetOffsetInsideRefreshArea:
            unsetRefreshingPadding()
            return .top

        default:
            return .none
        }
    }

    // MARK: - Refreshing Padding

    func setRefreshingPadding(done: @escaping () -> Void) {
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

    func unsetRefreshingPadding() {
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
        case willStartRefreshing

        /// Used to temporarily block balance animations during pull-to-refresh.
        /// For this purpose, all non-idle states are treated as `true`.
        public var isRefreshing: Bool {
            if case .idle = self {
                return false
            }
            return true
        }
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
