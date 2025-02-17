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

    @MainActor
    private var storyEnrichTask: Task<Void, Never>?

    @MainActor
    private var storyFinalizeTask: Task<Void, Never>?

    @MainActor
    @Published private(set) var state: State?

    init(
        checkStoryAvailabilityUseCase: CheckStoryAvailabilityUseCase,
        enrichStoryUseCase: EnrichStoryUseCase,
        finalizeStoryUseCase: FinalizeStoryUseCase
    ) {
        self.checkStoryAvailabilityUseCase = checkStoryAvailabilityUseCase
        self.enrichStoryUseCase = enrichStoryUseCase
        self.finalizeStoryUseCase = finalizeStoryUseCase
    }

    deinit {
        storyEnrichTask?.cancel()
        storyFinalizeTask?.cancel()
    }

    @MainActor
    func present(story: TangemStory, presentCompletion: @escaping () -> Void) {
        guard checkStoryAvailabilityUseCase(story.id) else {
            presentCompletion()
            return
        }

        storyEnrichTask?.cancel()
        storyFinalizeTask?.cancel()

        state = Self.makeState(for: story) { [weak self] in
            self?.finalizeActiveStory()
        }

        Task {
            let extraDelay = 0.3
            try await Task.sleep(seconds: TangemStoriesHostView.Constants.animationDuration + extraDelay)
            presentCompletion()
        }

        enrichStory(story)
    }

    @MainActor
    func forceDismiss() {
        storyEnrichTask?.cancel()
        finalizeActiveStory()
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
    private func finalizeActiveStory() {
        defer { state = nil }

        guard let lastActiveStory = state?.activeStory else { return }

        storyFinalizeTask = Task { [finalizeStoryUseCase] in
            await finalizeStoryUseCase(lastActiveStory.id)
        }
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
    struct State: Equatable {
        let storiesHostViewModel: StoriesHostViewModel
        var activeStory: TangemStory

        static func == (lhs: TangemStoriesViewModel.State, rhs: TangemStoriesViewModel.State) -> Bool {
            lhs.activeStory.id == rhs.activeStory.id
        }
    }
}
