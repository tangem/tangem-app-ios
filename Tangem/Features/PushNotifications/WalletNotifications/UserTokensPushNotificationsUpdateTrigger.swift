//
//  UserTokensPushNotificationsUpdateTrigger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import Foundation
import Combine
import CombineExt
import TangemFoundation

/// Monitors wallet readiness conditions and emits events that drive push-notification
/// settings updates. Extracted so the trigger logic can be reasoned about and tested
/// independently from the manager that acts on those events.
final class UserTokensPushNotificationsUpdateTrigger {
    var eventsPublisher: AnyPublisher<PushNotificationsUpdateTriggerEvent, Never> {
        eventsSubject.eraseToAnyPublisher()
    }

    /// Local mirror of `permissionService.isAuthorizedPublisher`. The upstream publisher only
    /// emits on `UIApplication.didBecomeActiveNotification`, so we keep the latest reported value
    /// here. Starts as `.idle` — consumers must skip that state instead of treating it as `false`.
    private let isAuthorizedSubject = CurrentValueSubject<AuthorizationState, Never>(.idle)

    private let userWalletId: UserWalletId
    private let eventsSubject = PassthroughSubject<PushNotificationsUpdateTriggerEvent, Never>()
    private var bag: Set<AnyCancellable> = []

    /// Stream of authorization values with `idle` filtered out, so downstream operators only see
    /// real readings reported by the permission service.
    private var isAuthorizedValuePublisher: AnyPublisher<Bool, Never> {
        isAuthorizedSubject
            .compactMap { state in
                switch state {
                case .idle: return nil
                case .value(let isAuthorized): return isAuthorized
                }
            }
            .eraseToAnyPublisher()
    }

    init(
        userWalletId: UserWalletId,
        accountModelsManager: AccountModelsManager,
        permissionService: PushNotificationsPermissionService,
        remoteTransactionAlertsStatePublisher: AnyPublisher<PushRemoteValueState<Bool>, Never>
    ) {
        self.userWalletId = userWalletId
        bind(
            accountModelsManager: accountModelsManager,
            permissionService: permissionService,
            remoteTransactionAlertsStatePublisher: remoteTransactionAlertsStatePublisher
        )
    }

    // MARK: - Private

    private func bind(
        accountModelsManager: AccountModelsManager,
        permissionService: PushNotificationsPermissionService,
        remoteTransactionAlertsStatePublisher: AnyPublisher<PushRemoteValueState<Bool>, Never>
    ) {
        permissionService
            .isAuthorizedPublisher
            .map(AuthorizationState.value)
            .subscribe(isAuthorizedSubject)
            .store(in: &bag)

        let isUserTokenListReadyPublisher = accountModelsManager
            .cryptoAccountModelsPublisher
            .flatMapLatest { cryptoAccountModels -> AnyPublisher<Bool, Never> in
                guard cryptoAccountModels.isNotEmpty else {
                    return .just(output: false)
                }

                return cryptoAccountModels
                    .map { $0.userTokensManager.userTokensPublisher }
                    .combineLatest()
                    .mapToValue(true)
                    .eraseToAnyPublisher()
            }
            .filter { $0 }
            .share(replay: 1)

        accountModelsManager
            .cryptoAccountModelsPublisher
            .flatMapLatest { cryptoAccountModels -> AnyPublisher<Bool, Never> in
                let hasPendingDerivationsPublishers = cryptoAccountModels
                    .compactMap { $0.userTokensManager.derivationManager?.hasPendingDerivations }

                guard hasPendingDerivationsPublishers.isNotEmpty else {
                    return .just(output: false)
                }

                return hasPendingDerivationsPublishers
                    .combineLatest()
                    .map { $0.contains(true) }
                    .eraseToAnyPublisher()
            }
            .pairwise()
            .filter { previous, current in
                // Proceed further only when pending derivations are finished
                return previous != current && current == false
            }
            .combineLatest(isUserTokenListReadyPublisher)
            .map { _ in PushNotificationsUpdateTriggerEvent.syncRemoteStatusRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)

        // Fire on every known auth reading instead of `pairwise()`-based change detection: the
        // upstream publisher only emits on `didBecomeActive` and never replays, so when the trigger
        // is created after the cold-start activation we'd otherwise stay one emission short of a
        // pair and miss the very first transition (e.g. user disabling push permission in Settings
        // and returning). `updateStatusIfNeeded()` deduplicates by comparing against the current
        // stored status, so extra invocations don't produce redundant emissions.
        isAuthorizedValuePublisher
            .removeDuplicates()
            .combineLatest(isUserTokenListReadyPublisher)
            .receiveOnMain()
            .map { _ in PushNotificationsUpdateTriggerEvent.updateStatusRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)

        let hasNotCompletedAllowanceOnboardingPublisher = PushNotificationsAllowanceBootstrapPolicy
            .hasNotCompletedOnboardingPublisher(userWalletId: userWalletId)

        let isPreferencesReadyPublisher = remoteTransactionAlertsStatePublisher
            .map { remoteState -> Bool in
                guard case .ready = remoteState else { return false }
                return true
            }
            .removeDuplicates()
            .eraseToAnyPublisher()

        // `isPreferencesReady == true` means the wallet is synced with the backend — that's the
        // primary trigger for auto-enabling preferences. Auth state and other readiness flags are
        // gated in via `combineLatest` so they contribute their latest values without driving the
        // emission cadence.
        isPreferencesReadyPublisher
            .filter { $0 }
            .combineLatest(
                isAuthorizedValuePublisher.removeDuplicates(),
                isUserTokenListReadyPublisher,
                hasNotCompletedAllowanceOnboardingPublisher
            )
            .filter { _, _, isUserTokenListReady, hasNotCompletedAllowanceOnboarding in
                isUserTokenListReady && hasNotCompletedAllowanceOnboarding
            }
            .receiveOnMain()
            .print("UserTokensPushNotificationsUpdateTrigger")
            .map { _ in PushNotificationsUpdateTriggerEvent.autoEnablePreferencesRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)

        // Backend transactional-push address sync when the settled remote toggle changes,
        // gated on the token list being ready.
        remoteTransactionAlertsStatePublisher
            .removeDuplicates()
            .pairwise()
            .filter { previous, current in
                guard case .ready(let previousValue) = previous, case .ready(let currentValue) = current else {
                    return false
                }

                return previousValue != currentValue
            }
            .combineLatest(isUserTokenListReadyPublisher)
            .map { _ in PushNotificationsUpdateTriggerEvent.syncRemoteStatusRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)
    }
}

private extension UserTokensPushNotificationsUpdateTrigger {
    /// Tri-state mirror of the system push-authorization flag. `idle` means the upstream
    /// publisher hasn't reported yet and the value must not be treated as `false`; downstream
    /// pipelines drop `idle` instead of acting on an unknown state.
    enum AuthorizationState: Hashable {
        case idle
        case value(Bool)
    }
}
