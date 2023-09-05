//
//  FakeUserWalletNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeUserWalletNotificationManager: NotificationManager {
    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationSubject.eraseToAnyPublisher()
    }

    private let notificationSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    func dismissNotification(with id: NotificationViewId) {
        notificationSubject.value.removeAll(where: { $0.id == id })
    }
}
