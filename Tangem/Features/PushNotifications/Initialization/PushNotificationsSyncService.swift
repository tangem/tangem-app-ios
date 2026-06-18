//
//  PushNotificationsSyncService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UserTokensPushNotificationsService: AnyObject {
    func initialize()
}

private struct PushNotificationsSyncServiceKey: InjectionKey {
    static var currentValue: UserTokensPushNotificationsService = CommonPushNotificationsSyncService()
}

extension InjectedValues {
    var userTokensPushNotificationsService: UserTokensPushNotificationsService {
        get { Self[PushNotificationsSyncServiceKey.self] }
        set { Self[PushNotificationsSyncServiceKey.self] = newValue }
    }
}
