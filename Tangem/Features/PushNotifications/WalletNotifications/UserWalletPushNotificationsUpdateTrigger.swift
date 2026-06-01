//
//  UserWalletPushNotificationsUpdateTrigger.swift
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
final class UserWalletPushNotificationsUpdateTrigger {
    var eventsPublisher: AnyPublisher<PushNotificationsUpdateTriggerEvent, Never> {
        eventsSubject.eraseToAnyPublisher()
    }

    /// Local mirror of `isAuthorizedPublisher` (which only emits on `didBecomeActive`). Starts at
    /// `.idle` so downstream can distinguish "no reading yet" from a real `false`.
    private let isAuthorizedSubject = CurrentValueSubject<AuthorizationState, Never>(.idle)

    private let userWalletId: UserWalletId
    private let eventsSubject = PassthroughSubject<PushNotificationsUpdateTriggerEvent, Never>()
    private var bag: Set<AnyCancellable> = []

    /// `isAuthorizedSubject` with `.idle` filtered out — emits only real permission readings.
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
        notificationPreferencesProvider: NotificationPreferencesProvider
    ) {
        self.userWalletId = userWalletId
        seedInitialAuthorizationState(permissionService: permissionService)
        bind(
            accountModelsManager: accountModelsManager,
            permissionService: permissionService,
            notificationPreferencesProvider: notificationPreferencesProvider
        )
    }

    // MARK: - Private

    private func seedInitialAuthorizationState(permissionService: PushNotificationsPermissionService) {
        // Seed `isAuthorizedSubject` with the current system permission so downstream pipelines
        // have a baseline even if the trigger is created after the cold-start `didBecomeActive`.
        Task { [weak self, permissionService] in
            let initial = await permissionService.isAuthorized
            self?.isAuthorizedSubject.send(.value(initial))
        }
    }

    private func bind(
        accountModelsManager: AccountModelsManager,
        permissionService: PushNotificationsPermissionService,
        notificationPreferencesProvider: NotificationPreferencesProvider
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

        // Fire on any flip of system permission (`true ↔ false`), typically the user toggling
        // push in iOS Settings. Needs two known readings, so it relies on at least one prior
        // `didBecomeActive`.
        isAuthorizedValuePublisher
            .removeDuplicates()
            .pairwise()
            .filter { previous, current in
                previous != current
            }
            .combineLatest(isUserTokenListReadyPublisher)
            .receiveOnMain()
            .map { _ in PushNotificationsUpdateTriggerEvent.updateStatusRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)

        let hasNotCompletedAllowanceOnboardingPublisher = PushNotificationsAllowanceBootstrapPolicy
            .hasNotCompletedOnboardingPublisher(userWalletId: userWalletId)

        let isPreferencesReadyPublisher = notificationPreferencesProvider
            .preferencesPublisher
            .map { preferences -> Bool in
                guard case .ready = preferences.state else { return false }
                return true
            }
            .removeDuplicates()
            .eraseToAnyPublisher()

        // Auto-enable preferences once everything is ready: backend synced (`isPreferencesReady`),
        // token list loaded, onboarding not yet completed, and system permission granted. Auth has
        // no `removeDuplicates()` on purpose — a late-arriving reading must still re-emit. The
        // manager dedupes downstream and ends the loop by flipping the onboarding flag to `false`.
        isPreferencesReadyPublisher
            .filter { $0 }
            .combineLatest(
                isAuthorizedValuePublisher,
                isUserTokenListReadyPublisher,
                hasNotCompletedAllowanceOnboardingPublisher
            )
            .filter { _, isAuthorized, isUserTokenListReady, hasNotCompletedAllowanceOnboarding in
                isAuthorized && isUserTokenListReady && hasNotCompletedAllowanceOnboarding
            }
            .receiveOnMain()
            .map { _ in PushNotificationsUpdateTriggerEvent.autoEnablePreferencesRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)

        // Backend transactional-push address sync when the settled remote toggle changes,
        // gated on the token list being ready.
        notificationPreferencesProvider
            .preferencesPublisher
            .map { $0.remoteValueState(for: .transactionAlerts) }
            .removeDuplicates()
            .pairwise()
            .filter { previous, current in
                switch (previous, current) {
                case (.ready(let previousPreference), .ready(let currentPreference)):
                    return previousPreference.isEnabled != currentPreference.isEnabled
                default:
                    return false
                }
            }
            .combineLatest(isUserTokenListReadyPublisher)
            .map { _ in PushNotificationsUpdateTriggerEvent.syncRemoteStatusRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)
    }
}

private extension UserWalletPushNotificationsUpdateTrigger {
    /// `.idle` means we haven't observed any permission reading yet — consumers must drop it
    /// instead of treating it as `false`.
    enum AuthorizationState: Hashable {
        case idle
        case value(Bool)
    }
}
