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
@available(iOS, deprecated: 100000.0, message: "Will be removed after full migration to channel-based push notifications. [REDACTED_INFO]")
final class UserTokensPushNotificationsUpdateTrigger {
    enum Event {
        /// Pending derivations just finished and the token list is ready — the remote
        /// push status should be re-synced with the backend.
        case syncRemoteStatusRequired
        /// System push authorization changed between foreground transitions while the token
        /// list is ready — the local push status should be recalculated.
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

        permissionService
            .isAuthorizedPublisher
            .pairwise()
            .filter { previous, current in
                previous != current
            }
            .combineLatest(isUserTokenListReadyPublisher)
            .receiveOnMain()
            .map { _ in Event.updateStatusRequired }
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
