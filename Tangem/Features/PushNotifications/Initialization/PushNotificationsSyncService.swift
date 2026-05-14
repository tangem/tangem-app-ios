//
//  PushNotificationsSyncService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol PushNotificationsSyncService: AnyObject {
    func initialize()
}

private struct PushNotificationsSyncServiceKey: InjectionKey {
    static var currentValue: PushNotificationsSyncService = CommonPushNotificationsSyncService()
}

extension InjectedValues {
    var pushNotificationsSyncService: PushNotificationsSyncService {
        get { Self[PushNotificationsSyncServiceKey.self] }
        set { Self[PushNotificationsSyncServiceKey.self] = newValue }
    }
}
