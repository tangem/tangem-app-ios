//
//  ActionButtonsSwapNoficationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

final class ActionButtonsSwapNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])

    private weak var delegate: NotificationTapDelegate?

    private var subscription: AnyCancellable?

    init(
        statePublisher: AnyPublisher<ActionButtonsSwapViewModel.ActionButtonsTokenSelectorState, Never>
    ) {
        subscription = statePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: weakify(
                self,
                forFunction: ActionButtonsSwapNotificationManager.setupNotifications(for:)
            ))
    }

    private func setupNotifications(
        for state: ActionButtonsSwapViewModel.ActionButtonsTokenSelectorState
    ) {
        switch state {
        case .refreshRequired(let title, let message):
            makeNotification(
                with: .refreshRequired(
                    title: title,
                    message: message
                )
            )
        case .noAvailablePairs:
            makeNotification(with: .noAvailablePairs)
        case .loaded, .loading, .initial, .readyToSwap:
            notificationInputsSubject.value = []
        }
    }

    func makeNotification(with event: ActionButtonsNotificationEvent) {
        let notificationsFactory = NotificationsFactory()

        let notification = notificationsFactory.buildNotificationInput(for: event) { [weak self] id, actionType in
            self?.delegate?.didTapNotification(with: id, action: actionType)
        }
        notificationInputsSubject.value = [notification]
    }
}

extension ActionButtonsSwapNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate

        setupNotifications(for: .loaded)
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
