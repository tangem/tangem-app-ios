//
//  TangemPayNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemPay
import TangemUI

final class TangemPayNotificationManager {
    private let userWalletModel: UserWalletModel
    private weak var delegate: (any NotificationTapDelegate)?

    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var cancellable: Cancellable?

    /// - Note: Workaround to avoid retain cycle for `UserWalletModel` instance in the Combine pipeline
    private var syncNeededTitle: String {
        userWalletModel.tangemPayAuthorizingInteractor.syncNeededTitle
    }

    /// - Note: Workaround to avoid retain cycle for `UserWalletModel` instance in the Combine pipeline
    private var mainButtonIcon: MainButton.Icon? {
        let provider = CommonTangemIconProvider(config: userWalletModel.config)

        return provider.getMainButtonIcon()
    }

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel

        cancellable = userWalletModel
            .accountModelsManager
            .tangemPayAccountModelPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { manager, accountModel -> AnyPublisher<[NotificationViewInput], Never> in
                guard let accountModel else {
                    return Just([]).eraseToAnyPublisher()
                }
                return accountModel.statePublisher
                    .withWeakCaptureOf(manager)
                    .map { [weak accountModel] manager, state in
                        let hasCachedAccount = accountModel?.lastKnownTangemPayAccount != nil
                        if hasCachedAccount, state.isSyncNeeded || state.isUnavailable {
                            return []
                        }
                        if let event = state.errorNotificationEvent(icon: manager.mainButtonIcon) {
                            return [manager.makeNotificationViewInput(event: event)]
                        }
                        return []
                    }
                    .eraseToAnyPublisher()
            }
            .sink(receiveValue: notificationInputsSubject.send)
    }

    private func makeNotificationViewInput(event: TangemPayNotificationEvent) -> NotificationViewInput {
        NotificationsFactory()
            .buildNotificationInput(
                for: event,
                buttonAction: { [weak self] id, action in
                    self?.delegate?.didTapNotification(with: id, action: action)
                },
                dismissAction: nil
            )
    }
}

// MARK: - NotificationManager

extension TangemPayNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject
            .eraseToAnyPublisher()
    }

    func setupManager(with delegate: (any NotificationTapDelegate)?) {
        self.delegate = delegate
    }

    func dismissNotification(with id: NotificationViewId) {
        // Notifications are not dismissable
    }
}
