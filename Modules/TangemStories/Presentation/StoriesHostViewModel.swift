//
//  StoriesHostViewModel.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import class UIKit.UIApplication
import TangemFoundation

@MainActor
public final class StoriesHostViewModel: ObservableObject {
    private let onStoriesFinished: () -> Void
    private var cancellables = Set<AnyCancellable>()

    @Published var visibleStoryIndex: Int
    @Published private(set) var allowsHitTesting = true

    public let storyViewModels: [StoryViewModel]

    public init(
        storyViewModels: [StoryViewModel],
        visibleStoryIndex: Int = 0,
        onStoriesFinished: @escaping () -> Void
    ) {
        assert(visibleStoryIndex < storyViewModels.count)

        self.storyViewModels = storyViewModels
        self.visibleStoryIndex = visibleStoryIndex
        self.onStoriesFinished = onStoriesFinished

        subscribeToStoriesEvents()
        subscribeToApplicationLifecycleEvents()
    }

    func pauseVisibleStory() {
        storyViewModels[visibleStoryIndex].handle(viewEvent: .viewInteractionPaused)
    }

    func resumeVisibleStory() {
        storyViewModels[visibleStoryIndex].handle(viewEvent: .viewInteractionResumed)
    }

    private func subscribeToStoriesEvents() {
        storyViewModels
            .enumerated()
            .forEach { index, viewModel in
                viewModel.storyTransitionPublisher
                    .sink { [weak self] transition in
                        self?.handleStoryTransition(index, transition: transition)
                    }
                    .store(in: &cancellables)

                viewModel.storyDismissIntentPublisher
                    .sink { [weak self] in
                        self?.onStoriesFinished()
                    }
                    .store(in: &cancellables)
            }
    }

    private func subscribeToApplicationLifecycleEvents() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.pauseVisibleStory()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.resumeVisibleStory()
            }
            .store(in: &cancellables)
    }

    private func handleStoryTransition(_ index: Int, transition: StoryViewModel.StoryTransition) {
        switch transition {
        case .forward:
            guard index < storyViewModels.count - 1 else {
                onStoriesFinished()
                return
            }
            updateVisibleStory(index: index + 1)

        case .backward:
            guard index > 0 else { return }
            let previousStoryViewModelIndex = index - 1
            storyViewModels[previousStoryViewModelIndex].handle(viewEvent: .willTransitionBackFromOtherStory)
            updateVisibleStory(index: previousStoryViewModelIndex)
        }
    }

    private func updateVisibleStory(index: Int) {
        allowsHitTesting = false
        visibleStoryIndex = index

        guard !AppEnvironment.current.isUITest else {
            allowsHitTesting = true
            return
        }

        // [REDACTED_USERNAME], prevents mid-transition break when user taps faster than animation duration.
        Task {
            try? await Task.sleep(seconds: Constants.storyTransitionDuration)
            allowsHitTesting = true
        }
    }
}

extension StoriesHostViewModel {
    private enum Constants {
        static let storyTransitionDuration: TimeInterval = 0.35
    }
}
