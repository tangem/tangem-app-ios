//
//  OnrampNotificationManager.swift
//  TangemApp
//
//  Created by Sergey Balashov on 20.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

protocol OnrampNotificationManagerInput {
    var errorPublisher: AnyPublisher<OnrampModelError?, Never> { get }
}

protocol OnrampNotificationManager: NotificationManager {
    func setup(input: OnrampNotificationManagerInput)
}

class CommonOnrampNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var inputSubscription: AnyCancellable?

    private weak var delegate: NotificationTapDelegate?

    init() {}
}

// MARK: - Bind

private extension CommonOnrampNotificationManager {
    func update(error: OnrampModelError?) {
        switch error {
        case .none:
            hideNotifications()
        case .loadingCountry(let error as ExpressAPIError),
             .loadingProviders(let error as ExpressAPIError),
             .loadingQuotes(let error as ExpressAPIError):
            show(event: .refreshRequired(
                title: error.localizedTitle,
                message: error.localizedMessage
            ))
        case .loadingCountry, .loadingProviders, .loadingQuotes:
            show(event: .refreshRequired(
                title: Localization.commonError,
                message: Localization.commonUnknownError
            ))
        }
    }
}

// MARK: - Show/Hide

private extension CommonOnrampNotificationManager {
    func show(event: OnrampNotificationEvent) {
        show(events: [event])
    }

    func show(events: [OnrampNotificationEvent]) {
        let factory = NotificationsFactory()

        notificationInputsSubject.value = events.map { event in
            factory.buildNotificationInput(for: event) { [weak self] id, actionType in
                self?.delegate?.didTapNotification(with: id, action: actionType)
            }
        }
    }

    func hideNotifications() {
        notificationInputsSubject.value.removeAll()
    }
}

// MARK: - NotificationManager

extension CommonOnrampNotificationManager: OnrampNotificationManager {
    func setup(input: any OnrampNotificationManagerInput) {
        inputSubscription = input.errorPublisher
            .withWeakCaptureOf(self)
            .sink { manager, error in
                manager.update(error: error)
            }
    }

    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
    }

    func dismissNotification(with id: NotificationViewId) {}
}

private extension TokenItem {
    var supportsStakingOnDifferentValidators: Bool {
        switch blockchain {
        case .tron: false
        default: true
        }
    }
}
