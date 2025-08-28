//
//  FakeYieldAccountNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class FakeYieldAccountNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationSubject.eraseToAnyPublisher()
    }

    private let notificationSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    func setupManager(with delegate: NotificationTapDelegate?) {}

    func dismissNotification(with id: NotificationViewId) {
        notificationSubject.value.removeAll(where: { $0.id == id })
    }
}
