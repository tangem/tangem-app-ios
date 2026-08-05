//
//  PushNotificationsSyncService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserWalletPushNotificationsService: AnyObject {
    func initialize()
}

private struct PushNotificationsSyncServiceKey: InjectionKey {
    static var currentValue: UserWalletPushNotificationsService = CommonPushNotificationsSyncService()
}

extension InjectedValues {
    var userWalletPushNotificationsService: UserWalletPushNotificationsService {
        get { Self[PushNotificationsSyncServiceKey.self] }
        set { Self[PushNotificationsSyncServiceKey.self] = newValue }
    }
}
