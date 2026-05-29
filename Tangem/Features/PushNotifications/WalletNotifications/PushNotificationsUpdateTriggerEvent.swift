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
    /// System push authorization changed between foreground transitions while the token
    /// list is ready — the local push status should be recalculated.
    case updateStatusRequired
    /// System push permission was granted (`false` → `true`) while the token list is
    /// ready — wallet-level preferences may be auto-enabled for allowance onboarding.
    case autoEnablePreferencesRequired
}
