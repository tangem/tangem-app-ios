//
//  NotificationPreferencesStateStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

actor NotificationPreferencesStateStore {
    private(set) var remoteStates: PushChannelRemoteStates = .allLoading
    private var lastConfirmedStates: PushChannelRemoteStates = .allLoading

    private var inFlightUpdateCount: Int = 0
    private var latestFetchToken: Int = 0
    private var latestUpdateToken: Int = 0

    func updateRemoteEnabled(
        _ state: PushRemoteValueState<Bool>,
        for channel: PushChannel
    ) -> PushChannelRemoteStates {
        switch state {
        case .loading:
            remoteStates = .allLoading
        case .failed:
            remoteStates = PushChannelRemoteStates(loadState: .failed)
        case .ready(let isEnabled):
            var states = remoteStates
            states.setEnabled(isEnabled, for: channel)
            remoteStates = states
        }

        return remoteStates
    }

    func beginFetch() -> Int {
        latestFetchToken += 1
        return latestFetchToken
    }

    func applyFetchResponse(
        _ response: NotificationPreferencesDTO.Response.Body,
        for token: Int
    ) -> PushChannelRemoteStates? {
        guard token == latestFetchToken else {
            return nil
        }

        // An optimistic write that hasn't reached the backend yet would be lost if we
        // applied this (now stale) server snapshot. Skip; the in-flight write will
        // update `lastConfirmedStates` itself, and a subsequent fetch will reconcile.
        guard inFlightUpdateCount == 0 else {
            return nil
        }

        let newStates = PushChannelRemoteStates(response: response)
        remoteStates = newStates
        lastConfirmedStates = newStates
        return newStates
    }

    func applyFetchFailure(for token: Int) -> PushChannelRemoteStates? {
        guard token == latestFetchToken else {
            return nil
        }

        guard case .loading = remoteStates.loadState else {
            return nil
        }

        let states = PushChannelRemoteStates(loadState: .failed)
        remoteStates = states
        return states
    }

    func beginUpdate(channel: PushChannel, isEnabled: Bool) -> UpdateContext {
        latestUpdateToken += 1
        inFlightUpdateCount += 1

        var optimisticStates = remoteStates
        optimisticStates.setEnabled(isEnabled, for: channel)

        // Always revert to a server-confirmed snapshot, never to whatever happens to be in
        // `remoteStates` right now — that value can already be optimistic from an
        // earlier rapid toggle whose PUT is still in flight.
        let rollbackTarget = lastConfirmedStates

        remoteStates = optimisticStates

        return .init(
            token: latestUpdateToken,
            optimisticStates: optimisticStates,
            rollbackTarget: rollbackTarget
        )
    }

    func finishUpdate(token: Int, completion: UpdateCompletion) -> PushChannelRemoteStates? {
        inFlightUpdateCount = max(0, inFlightUpdateCount - 1)

        guard token == latestUpdateToken else {
            return nil
        }

        switch completion {
        case .success(let optimisticStates):
            remoteStates = optimisticStates
            lastConfirmedStates = optimisticStates
            return nil
        case .failure(let rollbackTarget):
            remoteStates = rollbackTarget
            return rollbackTarget
        case .cancelled:
            return nil
        }
    }
}

extension NotificationPreferencesStateStore {
    struct UpdateContext {
        let token: Int
        let optimisticStates: PushChannelRemoteStates
        let rollbackTarget: PushChannelRemoteStates
    }

    enum UpdateCompletion {
        case success(PushChannelRemoteStates)
        case failure(PushChannelRemoteStates)
        case cancelled
    }
}
