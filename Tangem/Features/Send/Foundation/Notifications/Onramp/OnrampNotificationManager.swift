//
//  OnrampNotificationManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import TangemExpress

protocol OnrampNotificationManagerInput {
    var errorPublisher: AnyPublisher<Error?, Never> { get }
    /// Emits the token when it isn't onrampable (`onrampState == .unavailable`), `nil` otherwise.
    var unsupportedTokenPublisher: AnyPublisher<TokenItem?, Never> { get }
    var unsupportedCountryPublisher: AnyPublisher<OnrampCountry?, Never> { get }
}

protocol OnrampNotificationManager: NotificationManager {}

class CommonOnrampNotificationManager {
    private let notificationInputsSubject = CurrentValueSubject<[NotificationViewInput], Never>([])
    private var inputSubscription: AnyCancellable?

    private weak var delegate: NotificationTapDelegate?

    init(input: OnrampNotificationManagerInput, delegate: NotificationTapDelegate) {
        self.delegate = delegate

        bind(input: input)
    }
}

// MARK: - Bind

private extension CommonOnrampNotificationManager {
    func bind(input: some OnrampNotificationManagerInput) {
        inputSubscription = Publishers.CombineLatest3(
            input.errorPublisher.prepend(nil),
            input.unsupportedTokenPublisher.prepend(nil),
            input.unsupportedCountryPublisher
        )
        .withWeakCaptureOf(self)
        .sink { manager, args in
            let (error, unsupportedToken, unsupportedCountry) = args
            manager.update(error: error, unsupportedToken: unsupportedToken, unsupportedCountry: unsupportedCountry)
        }
    }

    func update(error: Error?, unsupportedToken: TokenItem?, unsupportedCountry: OnrampCountry?) {
        // The unsupported-token notice has priority and suppresses currency/residency errors — mirrors Swap's `unsupportedPair`.
        if let unsupportedToken {
            show(event: .tokenNotSupported(tokenName: unsupportedToken.name))
            return
        }

        if unsupportedCountry != nil {
            show(event: .countryNotSupported)
            return
        }

        switch error {
        case .none:
            hideNotifications()
        case .some(let error as ExpressAPIError):
            show(
                event: .refreshRequired(
                    title: error.localizedTitle,
                    message: error.localizedMessage
                )
            )
        case .some:
            show(
                event: .refreshRequired(
                    title: Localization.commonError,
                    message: Localization.commonUnknownError
                )
            )
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
