//
//  ForceUpdateState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum ForceUpdateState: Equatable {
    /// Version check hasn't completed yet (cache empty, first launch).
    case unknown
    /// The installed version is the latest supported one.
    case upToDate
    /// A newer version is available, but updating is optional. Banner on the main screen.
    case optionalUpdate(latestVersion: String)
    /// The user must take action before continuing. The blocking screen content depends on the reason.
    case forceUpdate(reason: ForceUpdateReason)

    var isOptionalUpdate: Bool {
        if case .optionalUpdate = self {
            return true
        }
        return false
    }

    var forceUpdateReason: ForceUpdateReason? {
        if case .forceUpdate(let reason) = self {
            return reason
        }
        return nil
    }
}

/// What the blocking force-update screen should communicate.
enum ForceUpdateReason: Equatable {
    /// App version is below the supported threshold; the user can upgrade via the App Store. Always blocks.
    case requiresAppUpdate
    /// App needs upgrading, but the device OS is too old to install the supported version.
    /// Soft warning — the user can dismiss it and keep using the app for the current session.
    case requiresOSUpdate
    /// App is permanently blocked: critical threshold not met and the OS cannot run the critical build either.
    /// Always blocks.
    case brick
}
