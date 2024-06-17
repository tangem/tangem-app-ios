//
//  PushNotificationsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum PushNotificationsProvider {
    static var isAvailable: Bool {
        // [REDACTED_TODO_COMMENT]
        FeatureProvider.isAvailable(.pushNotifications)
    }
}
