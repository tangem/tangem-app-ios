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

/// Publishes notification preference state updates while keeping mutable state
/// serialized in a dedicated actor.
final class CommonNotificationPreferencesProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let userWalletId: String
    private let stateStore = NotificationPreferencesStateStore()
    private let preferencesSubject = CurrentValueSubject<RemotePushPreferences, Never>(.loading)

    nonisolated init(userWalletId: String) {
        self.userWalletId = userWalletId
    }
}

// MARK: - NotificationPreferencesProvider

extension CommonNotificationPreferencesProvider: NotificationPreferencesProvider {
    var preferencesPublisher: AnyPublisher<RemotePushPreferences, Never> {
        preferencesSubject.eraseToAnyPublisher()
    }

    var preferences: RemotePushPreferences {
        preferencesSubject.value
    }

    func updateRemoteEnabled(_ state: PushRemoteValueState<Bool>, for channel: PushChannel) {
        runTask(in: self) { provider in
            let updated = await provider.stateStore.updateRemoteEnabled(state, for: channel)
            await provider.publish(updated)
        }
    }

    func fetchPreferences() async throws {
        do {
            let response = try await tangemApiService.getNotificationPreferences(
                userWalletId: userWalletId
            )

            try Task.checkCancellation()

            guard let newPreferences = await stateStore.applyFetchResponse(response) else {
                return
            }

            await publish(newPreferences)
        } catch {
            if error is CancellationError || Task.isCancelled {
                // The fetch was cancelled (e.g. the screen went away); do not turn loading into `.failed`.
                throw error
            }

            if let failedPreferences = await stateStore.applyFetchFailure() {
                await publish(failedPreferences)
            }

            throw error
        }
    }

    func updatePreferences(isEnabled: Bool, for channel: PushChannel) async throws {
        guard let context = await stateStore.beginUpdate(channel: channel, isEnabled: isEnabled) else {
            throw NotificationPreferencesUpdateError.writeRejected
        }

        await publish(context.optimisticPreferences)

        let request = NotificationPreferencesDTO.Body(preferences: context.optimisticPreferences)

        do {
            try await tangemApiService.updateNotificationPreferences(
                userWalletId: userWalletId,
                preferences: request
            )

            try Task.checkCancellation()

            _ = await stateStore.finishUpdate(completion: .success(context.optimisticPreferences))
            scheduleReconciliationFetchIfNeeded()
        } catch {
            // Roll back to the last server-confirmed snapshot on both failure and cancellation.
            // Single-flight means a cancelled write is never superseded by a newer one, so leaving
            // its unconfirmed optimistic value in `preferencesSubject` would desync it from
            // `lastConfirmedPreferences` and let the next write compose from an unconfirmed snapshot.
            if let rollbackPreferences = await stateStore.finishUpdate(completion: .failure(context.rollbackPreferences)) {
                await publish(rollbackPreferences)
            }

            scheduleReconciliationFetchIfNeeded()
            throw error
        }
    }

    func enableAll() async throws {
        guard let context = await stateStore.beginEnableAllUpdate() else {
            throw NotificationPreferencesUpdateError.writeRejected
        }

        await publish(context.optimisticPreferences)

        let request = NotificationPreferencesDTO.Body(preferences: context.optimisticPreferences)

        do {
            try await tangemApiService.updateNotificationPreferences(
                userWalletId: userWalletId,
                preferences: request
            )

            try Task.checkCancellation()

            _ = await stateStore.finishUpdate(completion: .success(context.optimisticPreferences))

            // The PUT is confirmed; refresh from the server but don't fail the operation if that
            // read fails — the optimistic snapshot is already the confirmed state.
            try? await fetchPreferences()

            // If the fetch above failed, a snapshot dropped during the write is still owed;
            // this retries it (no-op when the fetch already reconciled).
            scheduleReconciliationFetchIfNeeded()
        } catch {
            if let rollbackPreferences = await stateStore.finishUpdate(completion: .failure(context.rollbackPreferences)) {
                await publish(rollbackPreferences)
            }

            scheduleReconciliationFetchIfNeeded()
            throw error
        }
    }
}

// MARK: - Helpers

private extension CommonNotificationPreferencesProvider {
    @MainActor
    func publish(_ preferences: RemotePushPreferences) {
        preferencesSubject.send(preferences)
    }

    /// Re-fetches the server snapshot that `applyFetchResponse` had to drop while a write was
    /// in flight, now that those writes have settled. Fire-and-forget so the triggering update
    /// doesn't block on an extra round-trip.
    func scheduleReconciliationFetchIfNeeded() {
        runTask(in: self) { provider in
            guard await provider.stateStore.consumePendingFetchReconciliation() else {
                return
            }

            try? await provider.fetchPreferences()
        }
    }
}

// MARK: - Errors

enum NotificationPreferencesUpdateError: Error {
    /// The store refused the write: either there's no server-confirmed snapshot yet (a
    /// full-replace PUT would push all-`false` defaults for the untouched channels), or another
    /// write is still in flight (the screen is expected to keep the toggle disabled meanwhile).
    case writeRejected
}
