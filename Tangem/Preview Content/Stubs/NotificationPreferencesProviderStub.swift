//
//  NotificationPreferencesProviderStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class NotificationPreferencesProviderStub: NotificationPreferencesProvider {
    func updatePreferences(_ preferences: [(type: PushNotificationsSettingType, isEnabled: Bool)]) throws {}
}
