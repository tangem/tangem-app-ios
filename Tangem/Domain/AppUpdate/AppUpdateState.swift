//
//  AppUpdateState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum AppUpdateState: Equatable {
    /// Version check hasn't completed yet.
    case unknown
    /// The installed version is the latest supported one.
    case upToDate
    /// A newer version is available, but updating is optional. Banner
    case optionalUpdate(latestVersion: String)
    /// The backend requires the user to update before continuing. Block screen
    case forceUpdate

    var isOptionalUpdate: Bool {
        if case .optionalUpdate = self {
            return true
        }
        return false
    }
}
