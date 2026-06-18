//
//  PushNotificationsUpdateTriggerEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PushNotificationsUpdateTriggerEvent {
    /// Pending derivations just finished and the token list is ready — the remote
    /// push status should be re-synced with the backend.
    case syncRemoteStatusRequired
    /// System push permission flipped (`true ↔ false`) between foreground transitions while
    /// the token list is ready — typically the user toggled push notifications in iOS Settings
    /// and returned to the app. The local push status needs to be recalculated to reflect the
    /// new permission state. Note: explicit enables initiated by the user via the in-app toggle,
    /// and automatic enables right after backend sync, go through the manager directly rather
    /// than this event.
    case updateStatusRequired
    /// System push permission was granted (`false` → `true`) while the token list is
    /// ready — wallet-level preferences may be auto-enabled for allowance onboarding.
    case autoEnablePreferencesRequired
}
