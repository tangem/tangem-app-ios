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

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
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
        notificationInputsSubject.value.removeAll {
            guard let event = $0.settings.event as? TokenNotificationEvent else {
                return false
            }

            return event == .someNetworksUnreachable
        }
    }

    private func setupSomeNetworksUnreachable() {
        let containsNotification = notificationInputsSubject.value.contains {
            guard let event = $0.settings.event as? TokenNotificationEvent else {
                return false
            }

            return event == .someNetworksUnreachable
        }

        if containsNotification {
            return
        }

        let factory = NotificationsFactory()
        notificationInputsSubject.value.append(factory.buildNotificationInput(for: .someNetworksUnreachable))
    }
}

extension MultiWalletNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {}

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
