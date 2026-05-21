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
        case updateStatusRequired(isAuthorized: Bool)
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
        notificationPreferencesProvider: NotificationPreferencesProvider? = nil,
        permissionService: PushNotificationsPermissionService
    ) {
        self.userWalletId = userWalletId

        bind(
            accountModelsManager: accountModelsManager,
            notificationPreferencesProvider: notificationPreferencesProvider,
            permissionService: permissionService
        )
    }

    // MARK: - Private

    private func bind(
        accountModelsManager: AccountModelsManager,
        notificationPreferencesProvider: NotificationPreferencesProvider?,
        permissionService: PushNotificationsPermissionService
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
            .dropFirst()
            .receiveOnMain()
            .map { isAuthorized, _ in Event.updateStatusRequired(isAuthorized: isAuthorized) }
            .subscribe(eventsSubject)
            .store(in: &bag)

        let hasNotCompletedAllowanceOnboardingPublisher = AppSettings.shared
            .$allowanceUserWalletIdTransactionsPush
            .map { [userWalletId] allowanceWalletIds in
                !allowanceWalletIds.contains(userWalletId.stringValue)
            }
            .removeDuplicates()

        let isPreferencesReadyPublisher: AnyPublisher<Bool, Never> = notificationPreferencesProvider?
            .preferencesPublisher
            .map { preferences -> Bool in
                guard case .ready = preferences.state else { return false }
                return true
            }
            .eraseToAnyPublisher() ?? Just(false).eraseToAnyPublisher()

        permissionService
            .isAuthorizedPublisher
            .removeDuplicates()
            .pairwise()
            .filter { previous, current in
                previous == false && current == true
            }
            .combineLatest(isUserTokenListReadyPublisher, hasNotCompletedAllowanceOnboardingPublisher, isPreferencesReadyPublisher)
            .filter { _, isUserTokenListReady, hasNotCompletedAllowanceOnboarding, isPreferencesReady in
                isUserTokenListReady && hasNotCompletedAllowanceOnboarding && isPreferencesReady
            }
            .receiveOnMain()
            .map { _ in Event.autoEnablePreferencesRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)

        // Backend transactional-push address sync when the settled remote toggle changes,
        // gated on the token list being ready.
        notificationPreferencesProvider?
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
            .map { _ in Event.syncRemoteStatusRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)
    }
}
