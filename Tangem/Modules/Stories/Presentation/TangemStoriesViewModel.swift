//
//  TangemStoriesViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemStories

final class TangemStoriesViewModel: ObservableObject {
    private let checkStoryAvailabilityUseCase: CheckStoryAvailabilityUseCase
    private let enrichStoryUseCase: EnrichStoryUseCase
    private let finalizeStoryUseCase: FinalizeStoryUseCase
    private let analyticsService: StoryAnalyticsService

    @MainActor
    private var storyEnrichTask: Task<Void, Never>?

    @MainActor
    private var delayedPresentCompletionTask: Task<Void, Error>?

    @MainActor
    private var storyFinalizeTask: Task<Void, Never>?

    @MainActor
    @Published private(set) var state: State?

    init(
        checkStoryAvailabilityUseCase: CheckStoryAvailabilityUseCase,
        enrichStoryUseCase: EnrichStoryUseCase,
        finalizeStoryUseCase: FinalizeStoryUseCase,
        analyticsService: StoryAnalyticsService
    ) {
        self.checkStoryAvailabilityUseCase = checkStoryAvailabilityUseCase
        self.enrichStoryUseCase = enrichStoryUseCase
        self.finalizeStoryUseCase = finalizeStoryUseCase
        self.analyticsService = analyticsService
    }

    deinit {
        storyEnrichTask?.cancel()
        delayedPresentCompletionTask?.cancel()
        storyFinalizeTask?.cancel()
    }

    @MainActor
    func present(story: TangemStory, analyticsSource: Analytics.StoriesSource, presentCompletion: @escaping () -> Void) {
        guard checkStoryAvailabilityUseCase(story.id) else {
            presentCompletion()
            return
        }

        storyEnrichTask?.cancel()
        delayedPresentCompletionTask?.cancel()
        storyFinalizeTask?.cancel()

        state = Self.makeState(for: story) { [weak self] in
            self?.finalizeActiveStory(analyticsSource: analyticsSource)
        }

        delayedPresentCompletionTask = Task {
            let extraDelay = 0.7
            try await Task.sleep(seconds: TangemStoriesHostManager.Animation.appearingDuration + extraDelay)
            presentCompletion()
        }

        enrichStory(story)
    }

    @MainActor
    func forceDismiss() {
        storyEnrichTask?.cancel()
        finalizeActiveStory(analyticsSource: nil)
    }

    // MARK: - Private methods

    @MainActor
    private func enrichStory(_ story: TangemStory) {
        storyEnrichTask = Task { [enrichStoryUseCase, weak self] in
            let enrichedStory = await enrichStoryUseCase(story)
            self?.state?.activeStory = enrichedStory
        }
    }

    @MainActor
    private func finalizeActiveStory(analyticsSource: Analytics.StoriesSource?) {
        defer {
            state = nil
            delayedPresentCompletionTask?.cancel()
        }

        guard let state else { return }

        storyFinalizeTask = Task { [finalizeStoryUseCase] in
            await finalizeStoryUseCase(state.activeStory.id)
        }

        guard
            let analyticsSource,
            let viewedPageIndexes = state.storiesHostViewModel.storyViewModels.first?.viewedPageIndexes,
            let lastViewedIndex = viewedPageIndexes.max()
        else {
            return
        }

        analyticsService.reportShown(state.activeStory.id, lastViewedPageIndex: lastViewedIndex, source: analyticsSource)
    }
}

// MARK: - TangemStoriesPresenter conformance

extension TangemStoriesViewModel: TangemStoriesPresenter {}

// MARK: - Factory methods

@MainActor
extension TangemStoriesViewModel {
    private static func makeState(for story: TangemStory, onStoriesFinished: @escaping () -> Void) -> State {
        // [REDACTED_TODO_COMMENT]
        State(
            storiesHostViewModel: StoriesHostViewModel(
                storyViewModels: [Self.makeStoryViewModel(for: story)],
                onStoriesFinished: onStoriesFinished
            ),
            activeStory: story
        )
    }

    private static func makeStoryViewModel(for story: TangemStory) -> StoryViewModel {
        StoryViewModel(pagesCount: story.pagesCount)
    }
}

// MARK: - Nested types

extension TangemStoriesViewModel {
    struct State {
        let storiesHostViewModel: StoriesHostViewModel
        var activeStory: TangemStory
    }
}
