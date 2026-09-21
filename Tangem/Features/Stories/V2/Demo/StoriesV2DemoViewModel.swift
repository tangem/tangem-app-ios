//
//  StoriesV2DemoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemStories

/// Dev-only preview of the Stories V2 player from the Environment screen.
@MainActor
final class StoriesV2DemoViewModel: ObservableObject, Identifiable {
    let id = UUID()

    @Injected(\.storiesV2RemoteStore) private var remoteStore: StoriesV2RemoteStore
    @Injected(\.storiesV2AssetPrefetchService) private var assetPrefetchService: StoryAssetPrefetchService

    let storyIDs = StoriesV2StoryID.allCases

    @Published private(set) var statusMessage: String?
    @Published private(set) var loadingRequest: Request?
    /// By identity rather than a Bool: a boolean binding keeps reading "already presented" when
    /// a state change lands in the same update as the assignment, wedging the screen.
    @Published private(set) var presentedStory: PresentedStory?

    /// Single-flight: the list stays tappable for the seconds a story takes to arrive, and a
    /// late one must not replace an already-presented player.
    private var openTask: Task<Void, Never>?

    nonisolated init() {}

    func open(_ request: Request) {
        openTask?.cancel()
        loadingRequest = request

        openTask = Task { @MainActor in
            defer {
                if loadingRequest == request {
                    loadingRequest = nil
                }
            }

            do {
                let stories = try await remoteStore.stories(slugs: request.slugs)
                try Task.checkCancellation()
                await play(stories, requested: request.slugs)
            } catch is CancellationError {
            } catch {
                statusMessage = "Open failed: \(error)"
            }
        }
    }

    private func play(_ stories: [StoryV2], requested: [String]) async {
        statusMessage = report(stories, requested: requested)
        guard let story = stories.first else { return }

        let prefetched = await assetPrefetchService.prefetch(story)
        guard !Task.isCancelled else { return }
        present(story: prefetched)
    }

    /// Silence means everything asked for came back; anything the mapper dropped or the backend
    /// withheld is named instead.
    private func report(_ stories: [StoryV2], requested: [String]) -> String? {
        let missing = requested.filter { slug in !stories.contains { $0.id == slug } }

        switch (stories.first, missing.isEmpty) {
        case (nil, _):
            return "No story for \(requested.joined(separator: ", "))"
        case (let story?, true):
            return stories.count > 1 ? "\(stories.count) stories, playing \(story.id)" : nil
        case (let story?, false):
            return "Playing \(story.id), missing: \(missing.joined(separator: ", "))"
        }
    }

    func closePlayer() {
        presentedStory = nil
    }

    private func present(story: StoryV2) {
        // No provider is attached on this dev screen, so the source never reaches analytics.
        let player = StoryPlayerViewModel(
            story: story,
            source: .main,
            hapticPlayer: CommonStoryHapticPlayer()
        ) { [weak self] _, _ in
            self?.closePlayer()
        }
        presentedStory = PresentedStory(player: player)
    }
}

// MARK: - Request

extension StoriesV2DemoViewModel {
    enum Request: Hashable {
        case remote(StoriesV2StoryID)
        case remoteBatch

        var slugs: [String] {
            switch self {
            case .remote(let id): [id.rawValue]
            case .remoteBatch: StoriesV2StoryID.allCases.map(\.rawValue)
            }
        }
    }
}

// MARK: - PresentedStory

extension StoriesV2DemoViewModel {
    struct PresentedStory: Identifiable {
        let id = UUID()
        let player: StoryPlayerViewModel
    }
}
