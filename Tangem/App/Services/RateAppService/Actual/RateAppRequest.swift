//
//  RateAppRequest.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RateAppRequest {
    let isLocked: Bool
    let isSelected: Bool
    let isBalanceLoaded: Bool
    let displayedNotifications: [NotificationViewInput]
}
