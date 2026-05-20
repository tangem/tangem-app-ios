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
        let fetchToken = await stateStore.beginFetch()

        do {
            let response = try await tangemApiService.getNotificationPreferences(
                userWalletId: userWalletId
            )

            try Task.checkCancellation()

            guard let newPreferences = await stateStore.applyFetchResponse(
                response,
                for: fetchToken
            ) else {
                return
            }

            await publish(newPreferences)
        } catch {
            if error is CancellationError || Task.isCancelled {
                // A newer fetch has taken over; do not turn loading into `.failed`.
                throw error
            }

            if let failedPreferences = await stateStore.applyFetchFailure(for: fetchToken) {
                await publish(failedPreferences)
            }

            throw error
        }
    }

    func updatePreferences(isEnabled: Bool, for channel: PushChannel) async throws {
        let context = await stateStore.beginUpdate(channel: channel, isEnabled: isEnabled)
        await publish(context.optimisticPreferences)

        let request = NotificationPreferencesDTO.Update.Request(preferences: context.optimisticPreferences)

        do {
            try await tangemApiService.updateNotificationPreferences(
                userWalletId: userWalletId,
                preferences: request
            )

            try Task.checkCancellation()

            _ = await stateStore.finishUpdate(
                token: context.token,
                completion: .success(context.optimisticPreferences)
            )
        } catch {
            if error is CancellationError || Task.isCancelled {
                // A newer write has taken over and captured its own rollback target; leaving
                // `preferencesSubject` on the latest optimistic value is intentional.
                _ = await stateStore.finishUpdate(
                    token: context.token,
                    completion: .cancelled
                )
                throw error
            }

            if let rollbackPreferences = await stateStore.finishUpdate(
                token: context.token,
                completion: .failure(context.rollbackPreferences)
            ) {
                await publish(rollbackPreferences)
            }

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
}
