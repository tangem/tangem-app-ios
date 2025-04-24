//
//  StoryViewModel.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation

@MainActor
public final class StoryViewModel: ObservableObject {
    private let pagesCount: Int
    private let pageDuration: TimeInterval
    private var hasAppeared = false

    private lazy var timer = Timer.publish(every: Constants.timerTickDuration, on: .main, in: .common).autoconnect()
    private var timerCancellable: (any Cancellable)?

    private let storyTransitionSubject: PassthroughSubject<StoryTransition, Never>
    private let storyDismissIntentSubject: PassthroughSubject<Void, Never>

    private var timerIsRunning: Bool {
        timerCancellable != nil
    }

    private var storyHasFurtherPages: Bool {
        visiblePageIndex < pagesCount - 1
    }

    let storyTransitionPublisher: AnyPublisher<StoryTransition, Never>
    let storyDismissIntentPublisher: AnyPublisher<Void, Never>

    @Published private(set) var visiblePageProgress: CGFloat
    @Published private(set) var visiblePageIndex: Int

    public private(set) var viewedPageIndexes: Set<Int>

    public init(pagesCount: Int, pageDuration: TimeInterval = 8) {
        assert(pagesCount > 0, "Expected to have at least one page. Developer mistake")

        self.pagesCount = pagesCount
        self.pageDuration = pageDuration

        visiblePageProgress = 0
        visiblePageIndex = 0

        storyTransitionSubject = PassthroughSubject()
        storyTransitionPublisher = storyTransitionSubject.eraseToAnyPublisher()

        storyDismissIntentSubject = PassthroughSubject()
        storyDismissIntentPublisher = storyDismissIntentSubject.eraseToAnyPublisher()

        viewedPageIndexes = []
    }

    // MARK: - Internal methods

    func handle(viewEvent: StoryViewEvent) {
        switch viewEvent {
        case .viewDidAppear:
            handleViewDidAppear()

        case .viewDidDisappear:
            handleViewDidDisappear()

        case .viewInteractionPaused:
            handleViewInteractionPaused()

        case .viewInteractionResumed:
            handleViewInteractionResumed()

        case .longTapPressed:
            handleLongTapPressed()

        case .longTapEnded:
            handleLongTapEnded()

        case .tappedForward:
            handleTappedForward()

        case .tappedBackward:
            handleTappedBackward()

        case .closeButtonTapped:
            handleCloseButtonTapped()

        case .willTransitionBackFromOtherStory:
            handleWillTransitionBackFromOtherStory()
        }
    }

    func pageProgress(for index: Int) -> CGFloat {
        if index < visiblePageIndex {
            return 1
        } else if index == visiblePageIndex {
            return visiblePageProgress
        } else {
            return 0
        }
    }

    // MARK: - Private methods

    private func startTimer() {
        timerCancellable = timer
            .sink { [weak self] _ in
                guard let self else { return }

                let reachedLastPage = visiblePageIndex >= pagesCount - 1
                let reachedFullPageProgress = visiblePageProgress >= 1

                if reachedLastPage, reachedFullPageProgress {
                    stopTimer()
                    storyTransitionSubject.send(.forward)
                    return
                }

                incrementProgressFromTimer()
            }
    }

    private func stopTimer() {
        timerCancellable = nil
        timer.upstream.connect().cancel()
    }

    private func incrementProgressFromTimer() {
        let incrementedProgressValue = visiblePageProgress + Constants.timerTickDuration / pageDuration
        let maxProgressValue = 1.0

        guard incrementedProgressValue > maxProgressValue else {
            visiblePageProgress = incrementedProgressValue
            return
        }

        if storyHasFurtherPages {
            visiblePageIndex += 1
            visiblePageProgress = 0
            recordCurrentVisiblePageAsViewed()
        } else {
            visiblePageProgress = maxProgressValue
        }
    }

    private func recordCurrentVisiblePageAsViewed() {
        viewedPageIndexes.insert(visiblePageIndex)
    }
}

// MARK: - View events handling

extension StoryViewModel {
    private func handleViewDidAppear() {
        hasAppeared = true
        visiblePageProgress = 0
        recordCurrentVisiblePageAsViewed()
        startTimer()
    }

    private func handleViewDidDisappear() {
        hasAppeared = false
        stopTimer()
    }

    private func handleViewInteractionPaused() {
        stopTimer()
    }

    private func handleViewInteractionResumed() {
        guard hasAppeared else { return }
        startTimer()
    }

    private func handleLongTapPressed() {
        stopTimer()
    }

    private func handleLongTapEnded() {
        startTimer()
    }

    private func handleTappedForward() {
        if !timerIsRunning {
            startTimer()
        }

        guard storyHasFurtherPages else {
            storyTransitionSubject.send(.forward)
            return
        }

        visiblePageIndex += 1
        visiblePageProgress = 0

        recordCurrentVisiblePageAsViewed()
    }

    private func handleTappedBackward() {
        if !timerIsRunning {
            startTimer()
        }

        visiblePageProgress = 0

        guard visiblePageIndex > 0 else {
            storyTransitionSubject.send(.backward)
            return
        }

        visiblePageIndex -= 1
    }

    private func handleCloseButtonTapped() {
        storyDismissIntentSubject.send()
    }

    private func handleWillTransitionBackFromOtherStory() {
        visiblePageProgress = 0
    }
}

// MARK: - Nested types

extension StoryViewModel {
    enum StoryTransition {
        case forward
        case backward
    }

    private enum Constants {
        /// 0.05
        static let timerTickDuration: TimeInterval = 0.05
    }
}
