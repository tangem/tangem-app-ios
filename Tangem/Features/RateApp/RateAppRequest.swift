//
//  RateAppRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Controller to service communication messages.
struct RateAppRequest {
    let isLocked: Bool
    let isSelected: Bool
    let isBalanceLoaded: Bool
    let displayedNotifications: [NotificationViewInput]
}
