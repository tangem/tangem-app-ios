//
//  UserWalletNotificationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserWalletNotificationDelegate: AnyObject {
    func tapUserWalletNotification(with id: NotificationViewId)
}

/// Manager for handling Notifications related to UserWalletModel.
/// Don't forget to setup manager with delegate for proper notification handling
class UserWalletNotificationManager {
    @Injected(\.deprecationService) private var deprecationService: DeprecationServicing

    private let userWalletModel: UserWalletModel
    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private weak var delegate: UserWalletNotificationDelegate?
    private var updateSubscription: AnyCancellable?

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }

    func setupManager(with delegate: UserWalletNotificationDelegate? = nil) {
        self.delegate = delegate

        createNotifications()
        bind()
    }

    private func createNotifications() {
        let factory = NotificationsFactory()
        let action: NotificationView.NotificationAction = { [weak self] id in
            self?.delegate?.tapUserWalletNotification(with: id)
        }
        let dismissAction: NotificationView.NotificationAction = { [weak self] id in
            self?.dismissNotification(with: id)
        }

        let notificationInputsFromConfig = factory.buildNotificationInputs(
            for: userWalletModel.config.warningEvents,
            action: action,
            dismissAction: dismissAction
        )
        let deprecationNotificationInputs = factory.buildNotificationInputs(
            for: deprecationService.deprecationWarnings,
            action: action,
            dismissAction: dismissAction
        )

        notificationInputsSubject.send(deprecationNotificationInputs + notificationInputsFromConfig)

        validateHashesCount()
    }

    private func bind() {
        updateSubscription = userWalletModel.updatePublisher
            .sink(receiveValue: { [weak self] in
                self?.createNotifications()
            })
    }

    private func validateHashesCount() {
        let card = userWalletModel.userWallet.card
        let config = userWalletModel.config
        let cardId = card.cardId
        let cardSignedHashes = card.walletSignedHashes
        let isMultiWallet = config.hasFeature(.multiCurrency)
        let canCountHashes = config.hasFeature(.signedHashesCounter)

        func didFinishCountingHashes() {
            AppLog.shared.debug("⚠️ Hashes counted")
        }

        guard !AppSettings.shared.validatedSignedHashesCards.contains(cardId) else {
            didFinishCountingHashes()
            return
        }

        guard canCountHashes else {
            recordUserWalletHashesCountValidation()
            didFinishCountingHashes()
            return
        }

        guard cardSignedHashes > 0 else {
            recordUserWalletHashesCountValidation()
            didFinishCountingHashes()
            return
        }

        let factory = NotificationsFactory()
        guard !isMultiWallet else {
            didFinishCountingHashes()
            let notification = factory.buildNotificationInput(
                for: .multiWalletSignedHashes,
                action: delegate?.tapUserWalletNotification(with:) ?? { _ in },
                dismissAction: dismissNotification(with:)
            )
            notificationInputsSubject.value.append(notification)
            return
        }

        guard let validator = userWalletModel.walletModelsManager.signatureCountValidator else {
            didFinishCountingHashes()
            let notification = factory.buildNotificationInput(
                for: .numberOfSignedHashesIncorrect,
                action: delegate?.tapUserWalletNotification(with:) ?? { _ in },
                dismissAction: dismissNotification(with:)
            )
            notificationInputsSubject.value.append(notification)
            return
        }

        var validatorSubscription: AnyCancellable?
        validatorSubscription = validator.validateSignatureCount(signedHashes: cardSignedHashes)
            .subscribe(on: DispatchQueue.global())
            .handleEvents(receiveCancel: {
                AppLog.shared.debug("⚠️ Hash counter subscription cancelled")
            })
            .receive(on: DispatchQueue.main)
            .receiveCompletion { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    let notification = factory.buildNotificationInput(
                        for: .numberOfSignedHashesIncorrect,
                        action: { id in self?.delegate?.tapUserWalletNotification(with: id) },
                        dismissAction: { id in self?.dismissNotification(with: id) }
                    )
                    self?.notificationInputsSubject.value.append(notification)
                }
                didFinishCountingHashes()

                withExtendedLifetime(validatorSubscription) {}
            }
    }

    private func recordUserWalletHashesCountValidation() {
        let cardId = userWalletModel.userWallet.card.cardId
        AppSettings.shared.validatedSignedHashesCards.append(cardId)
    }

    private func recordDeprecationNotificationDismissal() {
        deprecationService.didDismissSystemDeprecationWarning()
    }
}

extension UserWalletNotificationManager: NotificationManager {
    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func dismissNotification(with id: NotificationViewId) {
        guard let notification = notificationInputsSubject.value.first(where: { $0.id == id }) else {
            return
        }

        switch notification.settings.event {
        case .systemDeprecationTemporary, .systemDeprecationPermanent:
            recordDeprecationNotificationDismissal()
        case .multiWalletSignedHashes, .numberOfSignedHashesIncorrect:
            recordUserWalletHashesCountValidation()
        default:
            break
        }

        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
