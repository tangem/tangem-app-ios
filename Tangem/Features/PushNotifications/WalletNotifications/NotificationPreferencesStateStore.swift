//
//  NotificationPreferencesStateStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

actor NotificationPreferencesStateStore {
    private(set) var preferences: RemotePushPreferences = .loading
    private var lastConfirmedPreferences: RemotePushPreferences = .loading

    private var inFlightUpdateCount: Int = 0
    private var latestFetchToken: Int = 0
    private var latestUpdateToken: Int = 0

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

    func beginFetch() -> Int {
        latestFetchToken += 1
        return latestFetchToken
    }

    func applyFetchResponse(
        _ response: NotificationPreferencesDTO.Response.Body,
        for token: Int
    ) -> RemotePushPreferences? {
        guard token == latestFetchToken else {
            return nil
        }

        // An optimistic write that hasn't reached the backend yet would be lost if we
        // applied this (now stale) server snapshot. Skip; the in-flight write will
        // update `lastConfirmedPreferences` itself, and a subsequent fetch will reconcile.
        guard inFlightUpdateCount == 0 else {
            return nil
        }

        let newPreferences = RemotePushPreferences(response: response)
        preferences = newPreferences
        lastConfirmedPreferences = newPreferences
        return newPreferences
    }

    func applyFetchFailure(for token: Int) -> RemotePushPreferences? {
        guard token == latestFetchToken else {
            return nil
        }

        guard case .loading = preferences.state else {
            return nil
        }

        let failed = RemotePushPreferences(state: .failed)
        preferences = failed
        return failed
    }

    func beginUpdate(channel: PushChannel, isEnabled: Bool) -> UpdateContext {
        var optimisticPreferences = preferences
        optimisticPreferences.setEnabled(isEnabled, for: channel)
        return beginUpdate(optimisticPreferences: optimisticPreferences)
    }

    func beginEnableAllUpdate() -> UpdateContext {
        var optimisticPreferences = preferences
        PushChannel.allCases.forEach { optimisticPreferences.setEnabled(true, for: $0) }
        return beginUpdate(optimisticPreferences: optimisticPreferences)
    }

    private func beginUpdate(optimisticPreferences: RemotePushPreferences) -> UpdateContext {
        latestUpdateToken += 1
        inFlightUpdateCount += 1

        // Always revert to a server-confirmed snapshot, never to whatever happens to be in
        // `preferences` right now — that value can already be optimistic from an
        // earlier rapid toggle whose PUT is still in flight.
        let rollbackPreferences = lastConfirmedPreferences

        preferences = optimisticPreferences

        return .init(
            token: latestUpdateToken,
            optimisticPreferences: optimisticPreferences,
            rollbackPreferences: rollbackPreferences
        )
    }

    func finishUpdate(token: Int, completion: UpdateCompletion) -> RemotePushPreferences? {
        inFlightUpdateCount = max(0, inFlightUpdateCount - 1)

        guard token == latestUpdateToken else {
            return nil
        }

        switch completion {
        case .success(let optimisticPreferences):
            preferences = optimisticPreferences
            lastConfirmedPreferences = optimisticPreferences
            return nil
        case .failure(let rollbackPreferences):
            preferences = rollbackPreferences
            return rollbackPreferences
        case .cancelled:
            return nil
        }
    }
}

extension NotificationPreferencesStateStore {
    struct UpdateContext {
        let token: Int
        let optimisticPreferences: RemotePushPreferences
        let rollbackPreferences: RemotePushPreferences
    }

    enum UpdateCompletion {
        case success(RemotePushPreferences)
        case failure(RemotePushPreferences)
        case cancelled
    }
}
