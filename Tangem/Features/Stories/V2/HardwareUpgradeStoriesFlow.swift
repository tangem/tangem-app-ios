//
//  HardwareUpgradeStoriesFlow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemStories

/// Opens the hardware upgrade destination, playing the promo stories in front of it for the
/// treatment arm. Both upgrade entry points go through here, so the arms cannot drift apart.
///
/// A reference type because one tap has to see that an earlier one is still loading.
final class HardwareUpgradeStoriesFlow {
    @Injected(\.storiesV2Presenter) private var presenter: any StoriesV2Presenter
    @Injected(\.storiesV2RemoteStore) private var remoteStore: StoriesV2RemoteStore
    @Injected(\.storiesV2AssetPrefetchService) private var assetPrefetchService: StoryAssetPrefetchService
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    private let resolver = HardwareUpgradeStoriesResolver()

    /// Touched from `start` only, which is main-actor bound.
    private var isLoading = false

    /// Locked rather than main-actor bound: `cancel` is called from the owner's `deinit`, which
    /// carries no actor of its own.
    private let loadTask = OSAllocatedUnfairLock<Task<Void, Never>?>(initialState: nil)

    /// `openHardwareWallet` runs exactly once in every branch, so the upgrade tap never becomes a
    /// dead end — unless the load is cancelled or the app tears the overlay down, either of which
    /// takes the tap with it.
    @MainActor
    func start(source: StorySource, openHardwareWallet: @escaping () -> Void) {
        // The load shows nothing on screen, so a second tap would silently send a duplicate
        // exposure and open a second story over the one about to appear.
        guard !isLoading else { return }

        guard resolver.shouldShowStories() else {
            openHardwareWallet()
            return
        }

        isLoading = true
        let sessionID = presenter.sessionID

        let task = runTask(in: self) { @MainActor flow in
            defer { flow.isLoading = false }

            do {
                let story = try await flow.loadStory()

                // The load outlives an app lock, which dismisses everything on the overlay and sends
                // the user to the lock screen. Neither the story nor its destination belongs there,
                // whether or not one came back.
                guard flow.presenter.sessionID == sessionID else { return }

                guard let story else {
                    openHardwareWallet()
                    return
                }

                let safariManager = flow.safariManager
                let incomingActionHandler = flow.incomingActionHandler

                flow.presenter.present(
                    story: story,
                    source: source,
                    presentCompletion: openHardwareWallet,
                    onExit: { exitReason, action in
                        // A screen target needs no routing: the destination is already up behind
                        // the player. A close target has nothing to open.
                        guard exitReason == .action, let target = action?.target else { return }

                        switch target {
                        case .web(let urlString):
                            if let url = URL(string: urlString) {
                                safariManager.openURL(url)
                            }
                        case .deeplink(let raw):
                            // The same entry the OS uses, so a story link behaves like a tapped one.
                            if let url = URL(string: raw) {
                                incomingActionHandler.handleIncomingURL(url)
                            }
                        case .screen, .close:
                            break
                        }
                    }
                )
            } catch is CancellationError {
                // The screen that asked for the story is gone, and so is the tap to answer.
            } catch {
                AppLogger.error("Hardware upgrade story load failed", error: error)

                guard flow.presenter.sessionID == sessionID else { return }

                openHardwareWallet()
            }
        }

        loadTask.withLock { $0 = task }
    }

    /// Stops the flow from presenting a story nobody waits for.
    func cancel() {
        loadTask.withLock { $0?.cancel() }
    }
}

// MARK: - Private implementation

private extension HardwareUpgradeStoriesFlow {
    /// Assets are expected to be warm from the app-start prefetch; a cold cache downloads them here.
    func loadStory() async throws -> StoryV2? {
        let stories = try await remoteStore.stories(slugs: [StoriesV2StoryID.hardwareUpgrade.rawValue])

        guard let story = stories.first else {
            return nil
        }

        return try await assetPrefetchService.prefetch(story)
    }
}
