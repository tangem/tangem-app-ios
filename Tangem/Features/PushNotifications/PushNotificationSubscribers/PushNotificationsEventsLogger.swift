//
//  PushNotificationsEventsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class PushNotificationsEventsLogger {
    // MARK: - Properties

    @Injected(\.pushNotificationsEventsPublisher) private var pushNotificationsEventsPublisher: PushNotificationEventsPublishing
    private var cancellable: AnyCancellable?

    // MARK: - Init

    public init() {
        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        cancellable = pushNotificationsEventsPublisher.eventsPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { logger, event in
                logger.logPushNotificationEvent(event)
            }
    }

    private func logPushNotificationEvent(_ event: PushNotificationsEvent) {
        switch event {
        case .authorization(.granted):
            AppLogger.info(Constants.authGrantedLogMessage)

        case .authorization(.deniedOrUndetermined):
            AppLogger.error(error: Constants.authDeniedLogMessage)

        case .authorization(.failed(let error)):
            AppLogger.error(Constants.authFailedLogMessage, error: error)

        case .receivedResponse:
            Analytics.log(.pushNotificationOpened)
        }
    }
}

// MARK: - Constants

private extension PushNotificationsEventsLogger {
    enum Constants {
        static let authGrantedLogMessage = "Push notification authorization granted; registering for remote notifications."
        static let authDeniedLogMessage = "Unable to request authorization and register for push notifications due to denied/undetermined authorization"
        static let authFailedLogMessage = "Unable to request authorization and register for push notifications due to error:"
    }
}
