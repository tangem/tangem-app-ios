//
//  PushChannel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Identifies a push-notification subsystem (wallet-level or preference channel).
enum PushChannel: String, CaseIterable, Hashable {
    case transactionAlerts
    case offersUpdates
    case priceAlerts
}
