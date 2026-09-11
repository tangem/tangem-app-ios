//
//  StoryPresentationViewModel.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum StoryPresentationState {
    case loading
    case ready(StoryPlayerViewModel)
    case failed
}

@MainActor
final class StoryPresentationViewModel: ObservableObject {
    @Published private(set) var state: StoryPresentationState = .loading

    private let storyId: String
    private let repository: StoriesRepository
    private let onClose: () -> Void
    /// Delivery failure is the entry flow's call (open Hardware wallet / dismiss), not the module's.
    private let onDeliveryFailure: () -> Void

    init(
        storyId: String,
        repository: StoriesRepository,
        onClose: @escaping () -> Void,
        onDeliveryFailure: @escaping () -> Void
    ) {
        self.storyId = storyId
        self.repository = repository
        self.onClose = onClose
        self.onDeliveryFailure = onDeliveryFailure
    }

    func start() async {
        do {
            let story = try await repository.story(id: storyId)
            // [REDACTED_TODO_COMMENT]
            // new home once the analyst confirms the visibility contract (per-id, per-placement,
            // client-side or backend-gated).
            state = .ready(makePlayer(for: story))
        } catch {
            state = .failed
            onDeliveryFailure()
        }
    }

    func close() { onClose() }

    private func makePlayer(for story: StoryV2) -> StoryPlayerViewModel {
        StoryPlayerViewModel(story: story) { [weak self] _, _ in
            self?.onClose()
        }
    }
}
