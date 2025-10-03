//
//  WalletYieldNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class WalletYieldNotificationManager {
    private let analyticsService: NotificationsAnalyticsService
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var bag: Set<AnyCancellable> = []

    // MARK: - Init

    init(userWalletId: UserWalletId) {
        analyticsService = NotificationsAnalyticsService(userWalletId: userWalletId)
        bind()
//        show()
    }

    // MARK: - Private Implementation

    private func show() {
        let event = MultiWalletNotificationEvent.someTokensNeedYieldApprove
        let input = NotificationsFactory().buildNotificationInput(for: event)
        notificationInputsSubject.send([input])
    }

    private func bind() {
        notificationPublisher
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink(receiveValue: { manager, notifications in
                manager.analyticsService.sendEventsIfNeeded(for: notifications)
            })
            .store(in: &bag)
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
