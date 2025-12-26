//
//  TangemPayNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class TangemPayNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private weak var delegate: NotificationTapDelegate?

    private var cancellable: Cancellable?

    init(paeraCustomerStatePublisher: AnyPublisher<TangemPayState, Never>) {
        cancellable = paeraCustomerStatePublisher
            .map(\.notificationEvent)
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

// MARK: - PaeraCustomer.State+notificationEvent

private extension TangemPayState {
    var notificationEvent: TangemPayNotificationEvent? {
        switch self {
        case .syncNeeded, .syncInProgress:
            .syncNeeded
        case .unavailable:
            .unavailable
        case .initial, .kyc, .issuingCard, .failedToIssueCard, .tangemPayAccount:
            nil
        }
    }
}
