//
//  NotificationPreferencesDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum NotificationPreferencesDTO {
    /// A single flat body shared by the GET response, the PUT request and the PUT echo response
    /// (contract v1.3). The backend dropped the per-channel `isVisible` flag entirely.
    struct Body: Codable, Equatable {
        let transactionEventsEnabled: Bool
        let offerUpdatesEnabled: Bool
        let priceAlertsEnabled: Bool
    }
}
