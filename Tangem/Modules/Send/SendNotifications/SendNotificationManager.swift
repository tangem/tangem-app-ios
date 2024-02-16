//
//  SendNotificationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol SendNotificationManagerInput {
    var feeValues: AnyPublisher<[FeeOption: LoadingValue<Fee>], Never> { get }
}

class SendNotificationManager {
    private let input: SendNotificationManagerInput
    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])
    private var bag: Set<AnyCancellable> = []

    private weak var delegate: NotificationTapDelegate?

    init(input: SendNotificationManagerInput) {
        self.input = input
    }

    var buttonAction: NotificationView.NotificationButtonTapAction {
        delegate?.didTapNotificationButton(with:action:) ?? { _, _ in }
    }

    private func bind() {
        input
            .feeValues
            .map {
                $0.contains { $0.value.error != nil }
            }
            .sink { [weak self] hasError in
                self?.updateEventVisibility(hasError, event: .networkFeeUnreachable)
            }
            .store(in: &bag)
    }

    private func updateEventVisibility(_ visible: Bool, event: SendNotificationEvent) {
        if !visible {
            notificationInputsSubject.value.removeAll { $0.settings.event.hashValue == event.hashValue }
        } else if !notificationInputsSubject.value.contains(where: { $0.settings.event.hashValue == event.hashValue }) {
            let input = NotificationsFactory().buildNotificationInput(for: event, buttonAction: buttonAction)
            notificationInputsSubject.value.append(input)
        }
    }
}

extension SendNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate
        bind()
    }

    func dismissNotification(with id: NotificationViewId) {}
}
