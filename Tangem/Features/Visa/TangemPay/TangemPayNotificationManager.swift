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

    init(
        tangemPayStatusPublisher: AnyPublisher<TangemPayStatus, Never>,
        tangemPayAccountStatePublisher: AnyPublisher<TangemPayAuthorizer.State, Never>
    ) {
        cancellable = Publishers.CombineLatest(
            tangemPayAccountStatePublisher.map(\.notificationEvent).prepend(nil),
            tangemPayStatusPublisher.map(\.notificationEvent).prepend(nil)
        )
        .map { [$0, $1].compactMap(\.self) }
        .withWeakCaptureOf(self)
        .map { manager, events in
            events.map(manager.makeNotificationViewInput)
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

// MARK: - TangemPayAuthorizer.State+notificationEvent

private extension TangemPayAuthorizer.State {
    var notificationEvent: TangemPayNotificationEvent? {
        switch self {
        case .authorized:
            nil

        case .syncNeeded:
            .syncNeeded

        case .unavailable:
            .unavailable
        }
    }
}
