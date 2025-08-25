//
//  NFTCollectionsListStateUpdater.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class NFTCollectionsListStateUpdater {
    typealias ViewState = NFTCollectionsListViewModel.ViewState
    typealias OnStateChange = (_ viewState: ViewState) -> Void

    var mostRecentState: ViewState? {
        stateUpdatesQueue.last
    }

    /// A FIFO queue to manage state updates.
    /// - Note: Using a true `Queue` data structure would be more appropriate, but definitely an overkill for this simple
    /// case since the size of the queue does not exceed a few items at any given time.
    private var stateUpdatesQueue: [ViewState] = [] {
        didSet { processStateUpdatesQueue() }
    }

    /// See `loadingStateStartThreshold` for details.
    private var pendingLoadingStateStartTimer: Timer?

    /// See `loadingStateMinDuration` for details.
    private var pendingStateUpdateTimer: Timer?

    /// The delay before showing a loading state to the user.
    /// This prevents brief loading indicators from flickering when data loads quickly.
    private let loadingStateStartThreshold: TimeInterval

    /// The minimum duration a loading state should be visible once shown.
    /// This ensures loading indicators don't disappear too quickly, which can cause UI jumpiness.
    private let loadingStateMinDuration: TimeInterval

    private let onStateChange: OnStateChange

    init(
        loadingStateStartThreshold: TimeInterval,
        loadingStateMinDuration: TimeInterval,
        onStateChange: @escaping OnStateChange
    ) {
        self.loadingStateStartThreshold = loadingStateStartThreshold
        self.loadingStateMinDuration = loadingStateMinDuration
        self.onStateChange = onStateChange
    }

    func updateState(to newValue: ViewState) {
        pendingLoadingStateStartTimer?.invalidate()
        pendingLoadingStateStartTimer = nil

        if newValue.isLoading {
            pendingLoadingStateStartTimer = Timer.scheduledTimer(withTimeInterval: loadingStateStartThreshold, repeats: false) { [weak self] timer in
                guard timer.isValid else {
                    return
                }
                self?.stateUpdatesQueue.append(newValue)
            }
        } else {
            stateUpdatesQueue.append(newValue)
        }
    }

    private func processStateUpdatesQueue() {
        guard
            stateUpdatesQueue.isNotEmpty,
            pendingStateUpdateTimer == nil
        else {
            // Another state update is already scheduled or there is no pending state at all, skipping
            return
        }

        let newState = stateUpdatesQueue.removeFirst()

        if newState.isLoading {
            pendingStateUpdateTimer = Timer.scheduledTimer(withTimeInterval: loadingStateMinDuration, repeats: false) { [weak self] _ in
                self?.pendingStateUpdateTimer = nil
                self?.processStateUpdatesQueue()
            }
        }

        onStateChange(newState)
    }
}
