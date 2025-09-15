//
//  WalletYieldNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class WalletYieldNotificationManager {
    private let analyticsService = NotificationsAnalyticsService()
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var updateSubscription: AnyCancellable?

    // MARK: - Init

    init() {
        analyticsService.setup(with: self, contextDataProvider: nil)

//        show()
    }

    // MARK: - Private Implementation

    private func show() {
        let event = MultiWalletNotificationEvent.someTokensNeedYieldApprove
        let input = NotificationsFactory().buildNotificationInput(for: event)
        notificationInputsSubject.send([input])
    }
}

// MARK: - NotificationManager

extension WalletYieldNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {}

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
