//
//  StoriesV2DemoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemStories

/// Dev-only preview of the Stories V2 player from the Environment screen.
@MainActor
final class StoriesV2DemoViewModel: ObservableObject, Identifiable {
    let id = UUID()

    @Injected(\.storiesV2RemoteStore) private var remoteStore: StoriesV2RemoteStore
    @Injected(\.storiesV2AssetPrefetchService) private var assetPrefetchService: StoryAssetPrefetchService
    @Injected(\.storiesV2Presenter) private var presenter: any StoriesV2Presenter

    let storyIDs = StoriesV2StoryID.allCases

    @Published private(set) var statusMessage: String?
    @Published private(set) var loadingRequest: Request?

    /// Single-flight: the list stays tappable for the seconds a story takes to arrive, and a
    /// late one must not replace an already-presented player.
    private var openTask: Task<Void, Never>?

    nonisolated init() {}

    func open(_ request: Request) {
        openTask?.cancel()
        loadingRequest = request

        openTask = runTask(in: self) { @MainActor viewModel in
            defer {
                if viewModel.loadingRequest == request {
                    viewModel.loadingRequest = nil
                }
            }

            do {
                let stories = try await viewModel.remoteStore.stories(slugs: request.slugs)
                try Task.checkCancellation()
                try await viewModel.play(stories, requested: request.slugs)
            } catch is CancellationError {
            } catch {
                viewModel.statusMessage = "Open failed: \(error)"
            }
        }
    }

    /// Leaving the screen while a story loads must not leave it to arrive over whatever comes next;
    /// the list stays tappable the whole time it loads, so that exit is a tap away.
    func cancel() {
        openTask?.cancel()
    }

    private func play(_ stories: [StoryV2], requested: [String]) async throws {
        statusMessage = report(stories, requested: requested)
        guard let story = stories.first else { return }

        let prefetched = try await assetPrefetchService.prefetch(story)

        // A row tapped meanwhile owns the player now, so this request must not take it.
        try Task.checkCancellation()

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

    /// Nothing to reveal behind the player here, and `main` is a nominal source for this dev screen.
    private func present(story: StoryV2) {
        presenter.present(story: story, source: .main, presentCompletion: {}, onExit: { _, _ in })
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
