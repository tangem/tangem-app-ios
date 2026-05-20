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

    func fetchPreferences() {
        runTask(in: self) { provider in
            let fetchToken = await provider.stateStore.beginFetch()

            do {
                let response = try await provider.tangemApiService.getNotificationPreferences(
                    userWalletId: provider.userWalletId
                )

                guard !Task.isCancelled else { return }

                guard let newStates = await provider.stateStore.applyFetchResponse(
                    response,
                    for: fetchToken
                ) else {
                    return
                }

                await provider.publish(newStates)
            } catch is CancellationError {
                // A newer fetch has taken over; do not turn loading entries into `.failed`.
            } catch {
                // Some networking stacks surface cooperative cancellation as a plain error
                // (e.g. `URLError(.cancelled)`) instead of `CancellationError`. The `isCancelled`
                // guard catches that variant.
                guard !Task.isCancelled else { return }

                guard let failedStates = await provider.stateStore.applyFetchFailure(for: fetchToken) else {
                    return
                }

                await provider.publish(failedStates)
            }
        }
    }

    func updatePreferences(_ preferences: [(channel: PushChannel, isEnabled: Bool)]) {
        runTask(in: self) { provider in
            let context = await provider.stateStore.beginUpdate(preferences: preferences)
            await provider.publish(context.optimisticStates)

            let request = NotificationPreferencesDTO.Update.Request(remoteStates: context.optimisticStates)

            do {
                try await provider.tangemApiService.updateNotificationPreferences(
                    userWalletId: provider.userWalletId,
                    preferences: request
                )

                if Task.isCancelled {
                    _ = await provider.stateStore.finishUpdate(
                        token: context.token,
                        completion: .cancelled
                    )
                    return
                }

                _ = await provider.stateStore.finishUpdate(
                    token: context.token,
                    completion: .success(context.optimisticStates)
                )
            } catch is CancellationError {
                // A newer write has taken over and captured its own rollback target; leaving
                // `remoteStatesSubject` on the latest optimistic value is intentional.
                _ = await provider.stateStore.finishUpdate(
                    token: context.token,
                    completion: .cancelled
                )
            } catch {
                if Task.isCancelled {
                    _ = await provider.stateStore.finishUpdate(
                        token: context.token,
                        completion: .cancelled
                    )
                    return
                }

                guard let rollbackStates = await provider.stateStore.finishUpdate(
                    token: context.token,
                    completion: .failure(context.rollbackTarget)
                ) else {
                    return
                }

                await provider.publish(rollbackStates)
            }
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
