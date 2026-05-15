//
//  NotificationPreferencesProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol NotificationPreferencesProvider: AnyObject {
    /// Optimistically updates the cache and sends a full-replace PUT in a background task.
    /// Automatically reverts the cache to the previous value if the request fails.
    func updatePreferences(_ preferences: [(type: PushNotificationsSettingType, isEnabled: Bool)]) throws
}
