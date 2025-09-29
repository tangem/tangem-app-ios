//
//  MobileUnlock+Notification.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Notification

public extension Notification.Name {
    /// Posted when a mobile unlocking starts.
    static let mobileUnlockDidStart = Notification.Name("com.tangem-sdk-ios.MobileUnlockDidStart")

    /// Posted when a mobile unlocking finishes, whether successfully or due to a failure.
    static let mobileUnlockDidFinish = Notification.Name("com.tangem-sdk-ios.MobileUnlockDidFinish")
}
