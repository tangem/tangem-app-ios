//
//  UserTokensPushNotificationsService.swift
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

private struct UserTokensPushNotificationsServiceKey: InjectionKey {
    static var currentValue: UserTokensPushNotificationsService = CommonUserTokensPushNotificationsService()
}

extension InjectedValues {
    var userTokensPushNotificationsService: UserTokensPushNotificationsService {
        get { Self[UserTokensPushNotificationsServiceKey.self] }
        set { Self[UserTokensPushNotificationsServiceKey.self] = newValue }
    }
}
