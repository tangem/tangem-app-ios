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
    private let remoteStatesSubject = CurrentValueSubject<PushChannelRemoteStates, Never>(.allLoading)

    nonisolated init(userWalletId: String) {
        self.userWalletId = userWalletId
    }
}

// MARK: - NotificationPreferencesProvider

extension CommonNotificationPreferencesProvider: NotificationPreferencesProvider {
    var remoteStatesPublisher: AnyPublisher<PushChannelRemoteStates, Never> {
        remoteStatesSubject.eraseToAnyPublisher()
    }

    var remoteStates: PushChannelRemoteStates {
        remoteStatesSubject.value
    }

    func updateRemoteEnabled(_ state: PushRemoteValueState<Bool>, for channel: PushChannel) {
        runTask(in: self) { provider in
            let states = await provider.stateStore.updateRemoteEnabled(state, for: channel)
            await provider.publish(states)
        }
    }

    func fetchPreferences() async throws {
        let fetchToken = await stateStore.beginFetch()

        do {
            let response = try await tangemApiService.getNotificationPreferences(
                userWalletId: userWalletId
            )

            try Task.checkCancellation()

            guard let newStates = await stateStore.applyFetchResponse(
                response,
                for: fetchToken
            ) else {
                return
            }

            await publish(newStates)
        } catch {
            if error is CancellationError || Task.isCancelled {
                // A newer fetch has taken over; do not turn loading into `.failed`.
                throw error
            }

            if let failedStates = await stateStore.applyFetchFailure(for: fetchToken) {
                await publish(failedStates)
            }

            throw error
        }
    }

    func updatePreferences(isEnabled: Bool, for channel: PushChannel) async throws {
        let context = await stateStore.beginUpdate(channel: channel, isEnabled: isEnabled)
        await publish(context.optimisticStates)

        let request = NotificationPreferencesDTO.Update.Request(remoteStates: context.optimisticStates)

        do {
            try await tangemApiService.updateNotificationPreferences(
                userWalletId: userWalletId,
                preferences: request
            )

            try Task.checkCancellation()

            _ = await stateStore.finishUpdate(
                token: context.token,
                completion: .success(context.optimisticStates)
            )
        } catch {
            if error is CancellationError || Task.isCancelled {
                // A newer write has taken over and captured its own rollback target; leaving
                // `remoteStatesSubject` on the latest optimistic value is intentional.
                _ = await stateStore.finishUpdate(
                    token: context.token,
                    completion: .cancelled
                )
                throw error
            }

            if let rollbackStates = await stateStore.finishUpdate(
                token: context.token,
                completion: .failure(context.rollbackTarget)
            ) {
                await publish(rollbackStates)
            }

            throw error
        }
    }
}

// MARK: - Helpers

private extension CommonNotificationPreferencesProvider {
    @MainActor
    func publish(_ states: PushChannelRemoteStates) {
        remoteStatesSubject.send(states)
    }
}
