//
//  StoriesV2Presenter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemStories

protocol StoriesV2Presenter {
    @MainActor var playerPublisher: AnyPublisher<StoryPlayerViewModel?, Never> { get }

    /// Identifies the current overlay session and changes on `forceDismiss`, so a caller that loads
    /// a story for seconds can tell that the tap it belongs to is gone before it presents anything.
    @MainActor var sessionID: UUID { get }

    /// Plays a story over the whole app.
    ///
    /// `presentCompletion` runs once while the player still covers the screen, so the caller can put
    /// its destination up behind it. It runs however the story ends, early exit included, so a tap
    /// that opened a story is never left without its destination — except under `forceDismiss`,
    /// which drops it along with the story.
    @MainActor
    func present(
        story: StoryV2,
        source: StorySource,
        presentCompletion: @escaping () -> Void,
        onExit: @escaping (StoryExitReason, StoryActionV2?) -> Void
    )

    /// Gives back a player the overlay could not put on screen. The story is gone, but its caller
    /// still gets the destination it was promised.
    @MainActor
    func releaseUnpresented(_ player: StoryPlayerViewModel)

    @MainActor
    func forceDismiss()
}

@MainActor
final class CommonStoriesV2Presenter: ObservableObject {
    @Injected(\.storiesAnalyticsProvider) private var analytics: any StoriesAnalyticsProvider

    @Published private(set) var player: StoryPlayerViewModel?

    private(set) var sessionID = UUID()

    private var presentCompletionTask: Task<Void, Error>?
    private var pendingPresentCompletion: (() -> Void)?

    /// The dependency graph is assembled off the main actor.
    nonisolated init() {}
}

// MARK: - StoriesV2Presenter

extension CommonStoriesV2Presenter: StoriesV2Presenter {
    var playerPublisher: AnyPublisher<StoryPlayerViewModel?, Never> {
        $player.eraseToAnyPublisher()
    }

    func present(
        story: StoryV2,
        source: StorySource,
        presentCompletion: @escaping () -> Void,
        onExit: @escaping (StoryExitReason, StoryActionV2?) -> Void
    ) {
        // Taking the slot from a story still on screen would strand the tap that opened it.
        runPendingPresentCompletion()
        pendingPresentCompletion = presentCompletion

        player = StoryPlayerViewModel(
            story: story,
            source: source,
            analytics: analytics,
            hapticPlayer: CommonStoryHapticPlayer(),
            onFinished: { [weak self] exitReason, action in
                // Before the player goes away, so dismissing uncovers the destination instead of
                // flashing the screen the story was opened from.
                self?.runPendingPresentCompletion()
                self?.player = nil
                onExit(exitReason, action)
            }
        )

        // Same delay as V1 stories: a sheet transition underneath must not show through before the
        // player has covered the screen.
        presentCompletionTask = Task.delayed(withDelay: Constants.destinationSetupDelay) { @MainActor [weak self] in
            self?.runPendingPresentCompletion()
        }
    }

    func releaseUnpresented(_ player: StoryPlayerViewModel) {
        // `@Published` publishes in `willSet`, so the refusal arrives while the assignment that
        // caused it is still in flight — clearing the slot here would be undone by it. By the next
        // hop the value has landed, and the identity check leaves a newer story alone.
        runTask(in: self) { @MainActor presenter in
            guard presenter.player === player else { return }

            presenter.runPendingPresentCompletion()
            presenter.player = nil
        }
    }

    func forceDismiss() {
        presentCompletionTask?.cancel()
        pendingPresentCompletion = nil
        sessionID = UUID()
        player = nil
    }
}

// MARK: - Private implementation

private extension CommonStoriesV2Presenter {
    func runPendingPresentCompletion() {
        presentCompletionTask?.cancel()

        let completion = pendingPresentCompletion
        pendingPresentCompletion = nil
        completion?()
    }
}

// MARK: - Constants

private extension CommonStoriesV2Presenter {
    enum Constants {
        static let destinationSetupDelay: Double = 1.1
    }
}
