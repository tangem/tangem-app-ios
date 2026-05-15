//
//  NotificationPreferencesProviderStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class NotificationPreferencesProviderStub: NotificationPreferencesProvider {
    var remoteStatus: UserWalletPushNotifyRemoteStatus = .idle

    func setRemoteStatus(_ status: UserWalletPushNotifyRemoteStatus) {
        remoteStatus = status
    }

    func updatePreferences(_ preferences: [(type: PushNotificationsSettingType, isEnabled: Bool)]) throws {}
}
