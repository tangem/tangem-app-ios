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
                if let accountModel {
                    accountModel.statePublisher
                        .withWeakCaptureOf(manager)
                        .map { manager, state in
                            if let event = state.asNotificationEvent() {
                                [manager.makeNotificationViewInput(event: event)]
                            } else {
                                []
                            }
                        }
                        .eraseToAnyPublisher()
                } else {
                    Just([]).eraseToAnyPublisher()
                }
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

// MARK: - TangemPayLocalState+notificationEvent

private extension TangemPayLocalState {
    func asNotificationEvent() -> TangemPayNotificationEvent? {
        switch self {
        case .unavailable:
            .unavailable

        case .loading,
             .kycRequired,
             .kycDeclined,
             .issuingCard,
             .failedToIssueCard,
             .tangemPayAccount,
             .syncNeeded,
             .syncInProgress:
            nil
        }
    }
}
