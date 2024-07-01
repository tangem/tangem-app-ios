//
//  PushNotificationsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PushNotificationsService {
    func requestAuthorizationAndRegister() async
    func registerIfPossible() async
}
