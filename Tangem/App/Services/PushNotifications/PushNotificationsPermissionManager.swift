//
//  PushNotificationsPermissionManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PushNotificationsPermissionManager {
    var canPostponePermissionRequest: Bool { get }

    func allowPermissionRequest() async
    func postponePermissionRequest()
}
