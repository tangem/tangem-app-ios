//
//  PushNotificationsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PushNotificationsService {
    var isAvailable: Bool { get async }

    func requestAuthorizationAndRegister() async -> Bool
}
