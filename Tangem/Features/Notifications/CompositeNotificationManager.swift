//
//  CompositeNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt

final class CompositeNotificationManager {
    private let managers: [NotificationManager]

    init(_ managers: [NotificationManager]) {
        self.managers = managers
    }
}

// MARK: - NotificationManager

extension CompositeNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        get async {
            var inputs: [NotificationViewInput] = []

            for manager in managers {
                inputs += await manager.notificationInputs
            }

            return inputs
        }
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        managers
            .map(\.notificationPublisher)
            .combineLatest()
            .map { $0.flatMap { $0 } }
            .eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        managers.forEach { $0.setupManager(with: delegate) }
    }

    func dismissNotification(with id: NotificationViewId) {
        managers.forEach { $0.dismissNotification(with: id) }
    }
}
