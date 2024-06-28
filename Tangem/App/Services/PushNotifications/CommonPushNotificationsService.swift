//
//  CommonPushNotificationsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

final class CommonPushNotificationsService {
    private let authorizationOptions: UNAuthorizationOptions = [
        .alert,
        .badge,
        .sound,
    ]

    private var userNotificationCenter: UNUserNotificationCenter { .current() }
    private let application: UIApplication

    init(application: UIApplication) {
        self.application = application
    }
}

// MARK: - PushNotificationsService protocol conformance

extension CommonPushNotificationsService: PushNotificationsService {
    func requestAuthorizationAndRegister() async -> Bool {
        do {
            if try await userNotificationCenter.requestAuthorization(options: authorizationOptions) {
                await registerForRemoteNotifications()
                return true
            } else {
                AppLog.shared.error(
                    "Unable to request authorization and register for push notifications due to denied/undetermined authorization"
                )
            }
        } catch {
            AppLog.shared.error("Unable to request authorization and register for push notifications due to error:")
            AppLog.shared.error(error)
        }

        return false
    }

    @MainActor
    private func registerForRemoteNotifications() async {
        application.registerForRemoteNotifications()
    }
}
