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

/// Monitors wallet readiness conditions and emits events that drive push-notification
/// settings updates. Extracted so the trigger logic can be reasoned about and tested
/// independently from the manager that acts on those events.
final class UserTokensPushNotificationsUpdateTrigger {
    enum Event {
        /// Pending derivations just finished and the token list is ready — the remote
        /// push status should be re-synced with the backend.
        case syncRemoteStatusRequired
        /// The app returned to foreground while the token list is ready — the local
        /// push status should be recalculated.
        case updateStatusRequired
    }

    var eventsPublisher: AnyPublisher<Event, Never> {
        eventsSubject.eraseToAnyPublisher()
    }

    private let eventsSubject = PassthroughSubject<Event, Never>()
    private var bag: Set<AnyCancellable> = []

    init(accountModelsManager: AccountModelsManager) {
        bind(accountModelsManager: accountModelsManager)
    }

    // MARK: - Private

    private func bind(accountModelsManager: AccountModelsManager) {
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

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .combineLatest(isUserTokenListReadyPublisher)
            .receiveOnMain()
            .map { _ in Event.updateStatusRequired }
            .subscribe(eventsSubject)
            .store(in: &bag)
    }
}
