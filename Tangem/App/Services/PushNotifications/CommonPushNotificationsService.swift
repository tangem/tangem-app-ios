//
//  CommonPushNotificationsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UserNotifications

final class CommonPushNotificationsService {}

// MARK: - PushNotificationsService protocol conformance

extension CommonPushNotificationsService: PushNotificationsService {
    @MainActor
    var isAvailable: Bool {
        get async {
            let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()

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
}
