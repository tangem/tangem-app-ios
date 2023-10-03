//
//  MultiWalletNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MultiWalletNotificationManager {
    private let walletModelsManager: WalletModelsManager

    private let eventsSubject: CurrentValueSubject<[TokenNotificationEvent], Never> = .init([])
    private var updateSubscription: AnyCancellable?

    init(walletModelsManager: WalletModelsManager) {
        self.walletModelsManager = walletModelsManager

        bind()
    }

    private func bind() {
        updateSubscription = walletModelsManager.walletModelsPublisher
            .removeDuplicates()
            .flatMap { walletModels in
                let coinsOnlyModels = walletModels.filter { !$0.tokenItem.isToken }
                return Publishers.MergeMany(coinsOnlyModels.map { $0.walletDidChangePublisher })
                    .map { _ in coinsOnlyModels }
                    .filter { walletModels in
                        walletModels.allConforms { !$0.state.isLoading }
                    }
            }
            .sink { [weak self] walletModels in
                guard walletModels.contains(where: { $0.state.isBlockchainUnreachable }) else {
                    self?.removeSomeNetworksUnreachable()
                    return
                }

                self?.setupSomeNetworksUnreachable()
            }
    }

    private func removeSomeNetworksUnreachable() {
        eventsSubject.value.removeAll(where: { $0 == .someNetworksUnreachable })
    }

    private func setupSomeNetworksUnreachable() {
        if eventsSubject.value.contains(.someNetworksUnreachable) {
            return
        }

        eventsSubject.value.append(.someNetworksUnreachable)
    }
}

extension MultiWalletNotificationManager: NotificationManager {
    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        eventsSubject
            .map { events in
                let factory = NotificationsFactory()

                return events.map { factory.buildNotificationInput(for: $0) }
            }
            .eraseToAnyPublisher()
    }

    func dismissNotification(with id: NotificationViewId) {
        eventsSubject.value.removeAll(where: { $0.hashValue == id })
    }
}
