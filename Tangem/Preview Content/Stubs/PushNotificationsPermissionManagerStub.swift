//
//  PushNotificationsPermissionManagerStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PushNotificationsPermissionManagerStub: PushNotificationsPermissionManager {
    var canPostponePermissionRequest: Bool { false }

    func allowPermissionRequest() async {}
    func postponePermissionRequest() {}
}
