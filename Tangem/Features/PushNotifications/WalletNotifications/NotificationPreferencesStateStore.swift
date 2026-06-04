//
//  NotificationPreferencesStateStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Serializes notification-preference state for one wallet.
///
/// The screen drives this as a single-flight writer: a channel toggle is disabled while its PUT
/// is in flight, so at most one write runs at a time. The store also enforces that defensively —
/// `beginUpdate` refuses while a write is in flight — which is what keeps the coordination this
/// small: with no overlapping writes there is no out-of-order completion to disambiguate, so no
/// per-operation tokens are needed.
///
/// `preferences` is the optimistic value the UI observes; `lastConfirmedPreferences` is the last
/// server-confirmed snapshot, used as the rollback baseline.
actor NotificationPreferencesStateStore {
    private(set) var preferences: RemotePushPreferences = .loading
    private var lastConfirmedPreferences: RemotePushPreferences = .loading

    private var isWriteInFlight = false
    private var pendingFetchReconciliation = false

    func updateRemoteEnabled(
        _ state: PushRemoteValueState<Bool>,
        for channel: PushChannel
    ) -> RemotePushPreferences {
        switch state {
        case .loading:
            preferences = .loading
        case .failed:
            preferences = RemotePushPreferences(state: .failed)
        case .ready(let isEnabled):
            var updated = preferences
            updated.setEnabled(isEnabled, for: channel)
            preferences = updated
        }

        return preferences
    }

    func applyFetchResponse(
        _ response: NotificationPreferencesDTO.Response.Body
    ) -> RemotePushPreferences? {
        // Applying a server snapshot now would clobber an optimistic write that hasn't reached
        // the backend yet. Skip it, but remember we owe a reconciliation fetch once the write
        // settles — otherwise this snapshot is lost until the next external fetch.
        guard !isWriteInFlight else {
            pendingFetchReconciliation = true
            return nil
        }

        let newPreferences = RemotePushPreferences(response: response)
        preferences = newPreferences
        lastConfirmedPreferences = newPreferences
        pendingFetchReconciliation = false
        return newPreferences
    }

    func applyFetchFailure() -> RemotePushPreferences? {
        guard case .loading = preferences.state else {
            return nil
        }

        let failed = RemotePushPreferences(state: .failed)
        preferences = failed
        return failed
    }

    /// Returns `true` once a fetch that was dropped during a write can be safely retried — i.e.
    /// the write has settled. The caller is then expected to re-fetch.
    func consumePendingFetchReconciliation() -> Bool {
        guard pendingFetchReconciliation, !isWriteInFlight else {
            return false
        }

        pendingFetchReconciliation = false
        return true
    }

    func beginUpdate(channel: PushChannel, isEnabled: Bool) -> UpdateContext? {
        // A full-replace PUT derives all three channel values from `preferences`, so we need a
        // genuine server-confirmed baseline to merge into. Checking `preferences.state` alone is
        // not enough: `updateRemoteEnabled` can flip `preferences` to `.ready` built from
        // all-`false` defaults before the first fetch, and the PUT would then push the untouched
        // channels as `false` and overwrite the user's real settings. `lastConfirmedPreferences`
        // is only set by a successful fetch or write, so require it to be `.ready` too. We also
        // keep at most one write in flight; a toggle arriving mid-write is refused.
        guard case .ready = preferences.state,
              case .ready = lastConfirmedPreferences.state,
              !isWriteInFlight else {
            return nil
        }

        isWriteInFlight = true

        var optimisticPreferences = preferences
        optimisticPreferences.setEnabled(isEnabled, for: channel)

        let rollbackPreferences = lastConfirmedPreferences
        preferences = optimisticPreferences

        return .init(
            optimisticPreferences: optimisticPreferences,
            rollbackPreferences: rollbackPreferences
        )
    }

    func finishUpdate(completion: UpdateCompletion) -> RemotePushPreferences? {
        isWriteInFlight = false

        switch completion {
        case .success(let optimisticPreferences):
            preferences = optimisticPreferences
            lastConfirmedPreferences = optimisticPreferences
            return nil
        case .failure(let rollbackPreferences):
            preferences = rollbackPreferences
            return rollbackPreferences
        }
    }
}

extension NotificationPreferencesStateStore {
    struct UpdateContext {
        let optimisticPreferences: RemotePushPreferences
        let rollbackPreferences: RemotePushPreferences
    }

    enum UpdateCompletion {
        case success(RemotePushPreferences)
        case failure(RemotePushPreferences)
    }
}
