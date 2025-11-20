//
//  TangemPayNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class TangemPayNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<NotificationViewInput?, Never>(.none)
    private weak var delegate: NotificationTapDelegate?

    private var cancellable: Cancellable?

    init(tangemPayStatusPublisher: AnyPublisher<TangemPayStatus, Never>) {
        cancellable = tangemPayStatusPublisher
            .map(\.notificationEvent)
            .withWeakCaptureOf(self)
            .map { manager, event in
                if let event {
                    manager.makeNotificationViewInput(event: event)
                } else {
                    nil
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
        guard let notification = notificationInputsSubject.value else {
            return []
        }
        return [notification]
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject
            .map { notification in
                guard let notification else {
                    return []
                }
                return [notification]
            }
            .eraseToAnyPublisher()
    }

    func setupManager(with delegate: (any NotificationTapDelegate)?) {
        self.delegate = delegate
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.send(.none)
    }
}

// MARK: - TangemPayStatus+notificationEvent

private extension TangemPayStatus {
    var notificationEvent: TangemPayNotificationEvent? {
        switch self {
        case .kycRequired:
            .viewKYCStatus

        case .readyToIssueOrIssuing:
            .createAccountAndIssueCard

        case .active, .blocked:
            nil
        }
    }
}
