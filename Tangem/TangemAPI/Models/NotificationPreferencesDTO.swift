//
//  NotificationPreferencesDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum NotificationPreferencesDTO {
    struct Preference: Codable, Equatable {
        let isEnabled: Bool
        let isVisible: Bool
    }

    enum Response {
        struct Body: Codable, Equatable {
            let transactionAlerts: Preference
            let offersUpdates: Preference
            let priceAlerts: Preference
        }
    }

    enum Update {
        struct Request: Encodable, Equatable {
            let transactionAlerts: Bool
            let offersUpdates: Bool
            let priceAlerts: Bool
        }
    }
}
