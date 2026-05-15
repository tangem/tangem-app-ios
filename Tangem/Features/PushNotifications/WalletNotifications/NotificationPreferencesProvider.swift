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
    /// Current remote push-notification status received from the backend.
    var remoteStatus: UserWalletPushNotifyRemoteStatus { get }

    /// Updates the stored remote status.
    func setRemoteStatus(_ status: UserWalletPushNotifyRemoteStatus)

    /// Optimistically updates the cache and sends a full-replace PUT in a background task.
    /// Automatically reverts the cache to the previous value if the request fails.
    func updatePreferences(_ preferences: [(type: PushNotificationsSettingType, isEnabled: Bool)]) throws
}
