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
    enum Event {
        /// Pending derivations just finished and the token list is ready — the remote
        /// push status should be re-synced with the backend.
        case syncRemoteStatusRequired
        /// The app returned to foreground while the token list is ready — the local
        /// push status should be recalculated with the current system authorization state.
        case updateStatusRequired
        /// System push permission was granted (`false` → `true`) while the token list is
        /// ready — wallet-level preferences may be auto-enabled for allowance onboarding.
        case autoEnablePreferencesRequired
    }

    var eventsPublisher: AnyPublisher<Event, Never> {
        eventsSubject.eraseToAnyPublisher()
    }

    private let userWalletId: UserWalletId
    private let eventsSubject = PassthroughSubject<Event, Never>()
    private var bag: Set<AnyCancellable> = []

    init(
        userWalletId: UserWalletId,
        accountModelsManager: AccountModelsManager,
        permissionService: PushNotificationsPermissionService,
        remoteTransactionAlertsStatePublisher: AnyPublisher<PushRemoteValueState<Bool>, Never>? = nil
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
        remoteTransactionAlertsStatePublisher: AnyPublisher<PushRemoteValueState<Bool>, Never>?
    ) {
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
            .map { _ in Event.syncRemoteStatusRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)

        permissionService.isAuthorizedPublisher
            .combineLatest(isUserTokenListReadyPublisher)
            .receiveOnMain()
            .map { _, _ in Event.updateStatusRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)

        let hasNotCompletedAllowanceOnboardingPublisher = PushNotificationsAllowanceBootstrapPolicy
            .hasNotCompletedOnboardingPublisher(userWalletId: userWalletId)

        let isPreferencesReadyPublisher = remoteTransactionAlertsStatePublisher?
            .map { remoteState -> Bool in
                guard case .ready = remoteState else { return false }
                return true
            }
            .removeDuplicates()
            .eraseToAnyPublisher() ?? Just(false).eraseToAnyPublisher()

        permissionService
            .isAuthorizedPublisher
            .removeDuplicates()
            .pairwise()
            .filter { previous, current in
                previous == false && current == true
            }
            .combineLatest(
                isUserTokenListReadyPublisher,
                hasNotCompletedAllowanceOnboardingPublisher,
                isPreferencesReadyPublisher
            )
            .filter { _, isUserTokenListReady, hasNotCompletedAllowanceOnboarding, isPreferencesReady in
                isUserTokenListReady && hasNotCompletedAllowanceOnboarding && isPreferencesReady
            }
            .receiveOnMain()
            .map { _ in Event.autoEnablePreferencesRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)

        // Backend transactional-push address sync when the settled remote toggle changes,
        // gated on the token list being ready.
        remoteTransactionAlertsStatePublisher?
            .removeDuplicates()
            .pairwise()
            .filter { previous, current in
                guard case .ready(let previousValue) = previous, case .ready(let currentValue) = current else {
                    return false
                }

                return previousValue != currentValue
            }
            .combineLatest(isUserTokenListReadyPublisher)
            .map { _ in Event.syncRemoteStatusRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)
    }
}
