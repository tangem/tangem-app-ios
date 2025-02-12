//
//  TangemStoriesViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemStories

@MainActor
final class TangemStoriesViewModel: ObservableObject {
    private let checkStoryAvailabilityUseCase: CheckStoryAvailabilityUseCase
    private let enrichStoryUseCase: EnrichStoryUseCase
    private let finalizeStoryUseCase: FinalizeStoryUseCase

    private var storyEnrichTask: Task<Void, Never>?
    private var storyFinalizeTask: Task<Void, Never>?

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

    func present(story: TangemStory) {
        guard checkStoryAvailabilityUseCase(story.id) else { return }

        storyEnrichTask?.cancel()
        storyFinalizeTask?.cancel()

        state = Self.makeState(for: story) { [weak self] in
            self?.finalizeActiveStory()
        }

        enrichStory(story)
    }

    // MARK: - Private methods

    private func enrichStory(_ story: TangemStory) {
        storyEnrichTask = Task { [enrichStoryUseCase, weak self] in
            let enrichedStory = await enrichStoryUseCase(story)
            self?.state?.activeStory = enrichedStory
        }
    }

    private func finalizeActiveStory() {
        defer { state = nil }

        guard let lastActiveStory = state?.activeStory else { return }

        storyFinalizeTask = Task { [finalizeStoryUseCase] in
            await finalizeStoryUseCase(lastActiveStory.id)
        }
    }
}

// MARK: - Factory methods

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
