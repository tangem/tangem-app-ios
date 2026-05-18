//
//  UserWalletPushNotifyRemoteStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum UserWalletPushNotifyRemoteStatus: Equatable {
    case idle
    case enabled
    case disabled
    /// Remote sync failed (network error, server error, etc.)
    case syncFailed

    var isEnabled: Bool {
        self == .enabled
    }
}
