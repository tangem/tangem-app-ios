//
//  CommonNotificationPreferencesProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// All mutable state lives on the main actor, so read-modify-write sequences over
/// `remoteStatesSubject`, `fetchTask`, `updateTask`, and the in-flight counter cannot race.
/// The class deliberately keeps two pieces of state in sync:
///
/// - `remoteStatesSubject` — the value broadcast to subscribers. May be optimistic.
/// - `lastConfirmedStates` — the latest snapshot the backend has acknowledged. Used as the
///   rollback target so that a failing PUT never reverts to a value that was itself only
///   optimistic.
@MainActor
final class CommonNotificationPreferencesProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: String
    private let remoteStatesSubject = CurrentValueSubject<PushChannelRemoteStates, Never>(.allLoading)
    private var lastConfirmedStates: PushChannelRemoteStates = .allLoading

    private var fetchTask: Task<Void, Never>?
    private var updateTask: Task<Void, Never>?

    /// Number of `updatePreferences` task bodies that have started but not yet returned.
    /// A non-zero value tells `fetchPreferences` that the backend snapshot it just received
    /// is older than the user's pending intent and must not clobber the optimistic state.
    private var inFlightUpdateCount: Int = 0

    private var hasInFlightUpdate: Bool { inFlightUpdateCount > 0 }

    nonisolated init(userWalletId: String) {
        self.userWalletId = userWalletId
    }
}

// MARK: - NotificationPreferencesProvider

extension CommonNotificationPreferencesProvider: NotificationPreferencesProvider {
    var remoteStates: PushChannelRemoteStates {
        remoteStatesSubject.value
    }

    func remoteState(for channel: PushChannel) -> RemoteValueState<PushChannelPreference> {
        remoteStates[channel]
    }

    func setRemoteState(_ state: RemoteValueState<PushChannelPreference>, for channel: PushChannel) {
        var states = remoteStatesSubject.value
        states[channel] = state
        remoteStatesSubject.send(states)
    }

    func fetchPreferences() {
        fetchTask?.cancel()
        fetchTask = runTask(in: self) { @MainActor provider in
            do {
                let response = try await provider.tangemApiService.getNotificationPreferences(
                    userWalletId: provider.userWalletId
                )

                guard !Task.isCancelled else { return }

                // An optimistic write that hasn't reached the backend yet would be lost if we
                // applied this (now stale) server snapshot. Skip; the in-flight write will
                // update `lastConfirmedStates` itself, and a subsequent fetch will reconcile.
                guard !provider.hasInFlightUpdate else { return }

                let newStates = PushChannelRemoteStates(response: response)
                provider.lastConfirmedStates = newStates
                provider.remoteStatesSubject.send(newStates)
            } catch is CancellationError {
                // A newer fetch has taken over; do not turn loading entries into `.failed`.
            } catch {
                // Some networking stacks surface cooperative cancellation as a plain error
                // (e.g. `URLError(.cancelled)`) instead of `CancellationError`. The `isCancelled`
                // guard catches that variant.
                guard !Task.isCancelled else { return }

                var states = provider.remoteStatesSubject.value
                for channel in PushChannel.allCases where states[channel] == .loading {
                    states[channel] = .failed
                }
                provider.remoteStatesSubject.send(states)
            }
        }
    }

    func updatePreferences(_ preferences: [(channel: PushChannel, isEnabled: Bool)]) {
        var optimisticStates = remoteStatesSubject.value
        for (channel, isEnabled) in preferences {
            optimisticStates.setEnabled(isEnabled, for: channel)
        }
        remoteStatesSubject.send(optimisticStates)

        let request = NotificationPreferencesDTO.Update.Request(remoteStates: optimisticStates)
        // Always revert to a server-confirmed snapshot, never to whatever happens to be in
        // `remoteStatesSubject` right now — that value can already be optimistic from an
        // earlier rapid toggle whose PUT is still in flight.
        let rollbackTarget = lastConfirmedStates

        inFlightUpdateCount += 1
        updateTask?.cancel()
        updateTask = runTask(in: self) { @MainActor provider in
            defer { provider.inFlightUpdateCount -= 1 }

            do {
                try await provider.tangemApiService.updateNotificationPreferences(
                    userWalletId: provider.userWalletId,
                    preferences: request
                )

                guard !Task.isCancelled else { return }

                provider.lastConfirmedStates = optimisticStates
            } catch is CancellationError {
                // A newer write has taken over and captured its own rollback target; leaving
                // `remoteStatesSubject` on the latest optimistic value is intentional.
            } catch {
                guard !Task.isCancelled else { return }

                provider.remoteStatesSubject.send(rollbackTarget)
            }
        }
    }
}
