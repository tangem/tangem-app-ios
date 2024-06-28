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
    var isAvailable: Bool {
        get async {
            let notificationSettings = await userNotificationCenter.notificationSettings()

            switch notificationSettings.authorizationStatus {
            case .notDetermined,
                 .provisional:
                return true
            case .denied,
                 .authorized,
                 .ephemeral:
                return false
            @unknown default:
                return false
            }
        }
    }

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
    private func registerForRemoteNotifications() {
        application.registerForRemoteNotifications()
    }
}
