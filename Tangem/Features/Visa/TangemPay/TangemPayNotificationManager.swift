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

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel

        cancellable = userWalletModel.tangemPayManager.statePublisher
            .map { state in
                state.asNotificationEvent(
                    syncNeededTitle: userWalletModel.tangemPayAuthorizingInteractor.syncNeededTitle,
                    icon: CommonTangemIconProvider(config: userWalletModel.config).getMainButtonIcon()
                )
            }
            .withWeakCaptureOf(self)
            .map { manager, event in
                if let event {
                    [manager.makeNotificationViewInput(event: event)]
                } else {
                    []
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
    func asNotificationEvent(syncNeededTitle: String, icon: MainButton.Icon?) -> TangemPayNotificationEvent? {
        switch self {
        case .syncNeeded, .syncInProgress:
            .syncNeeded(title: syncNeededTitle, icon: icon)

        case .unavailable:
            .unavailable

        case .initial, .loading, .kycRequired, .kycDeclined, .issuingCard, .failedToIssueCard, .tangemPayAccount:
            nil
        }
    }
}
