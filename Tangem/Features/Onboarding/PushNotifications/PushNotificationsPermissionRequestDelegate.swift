//
//  PushNotificationsPermissionRequestDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PushNotificationsPermissionRequestDelegate: AnyObject {
    func didFinishPushNotificationOnboarding()
    func didPostponePushNotifications()
}

extension PushNotificationsPermissionRequestDelegate {
    func didPostponePushNotifications() {
        didFinishPushNotificationOnboarding()
    }
}
