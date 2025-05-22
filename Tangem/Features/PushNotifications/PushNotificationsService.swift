//
//  PushNotificationsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import TangemFoundation

final class PushNotificationsService: NSObject {
    @Injected(\.pushNotificationsHandler) private var pushNotificationsHandler: PushNotificationsHandling
    
    /// - Note: Checks only explicit authorization (`UNAuthorizationStatus.authorized`) and ignores implicit
    /// authorization statuses such as `UNAuthorizationStatus.provisional` or `UNAuthorizationStatus.ephemeral`.
    @MainActor
    var isAuthorized: Bool {
        get async {
            let notificationSettings = await userNotificationCenter.notificationSettings()

            return notificationSettings.authorizationStatus == .authorized
        }
    }

    private let requestedAuthorizationOptions: UNAuthorizationOptions = [
        .alert,
        .badge,
        .sound,
    ]

    private let validAuthorizationStatuses: Set<UNAuthorizationStatus> = [
        .authorized,
        .ephemeral,
    ]

    private var respondedNotificationIds: Set<String> = []

    private let userNotificationCenter = UNUserNotificationCenter.current()
    private let application: UIApplication

    init(application: UIApplication) {
        self.application = application
        super.init()
        userNotificationCenter.delegate = pushNotificationsHandler
    }

    func requestAuthorizationAndRegister() async {
        do {
            if try await userNotificationCenter.requestAuthorization(options: requestedAuthorizationOptions) {
                await registerForRemoteNotifications()
            } else {
                AppLogger.error(error:
                    "Unable to request authorization and register for push notifications due to denied/undetermined authorization"
                )
            }
        } catch {
            AppLogger.error("Unable to request authorization and register for push notifications due to error:", error: error)
        }
    }

    func registerIfPossible() async {
        let notificationSettings = await userNotificationCenter.notificationSettings()
        if validAuthorizationStatuses.contains(notificationSettings.authorizationStatus) {
            await registerForRemoteNotifications()
        }
    }

    @MainActor
    private func registerForRemoteNotifications() async {
        if !AppEnvironment.current.isDebug {
            application.registerForRemoteNotifications()
        }
    }
}
