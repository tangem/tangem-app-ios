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
        syncNeededSignalPublisher: AnyPublisher<Void, Never>,
        unavailableSignalPublisher: AnyPublisher<Void, Never>,
        clearNotificationsSignalPublisher: AnyPublisher<Void, Never>
    ) {
        cancellable = Publishers.Merge3(
            syncNeededSignalPublisher.mapToValue(TangemPayNotificationEvent.syncNeeded),
            unavailableSignalPublisher.mapToValue(TangemPayNotificationEvent.unavailable),
            clearNotificationsSignalPublisher.mapToValue(nil)
        )
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
