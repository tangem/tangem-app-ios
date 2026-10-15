//
//  MobileWalletSocialBackup.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct MobileWalletSocialBackup: Sendable {
    public let walletId: String

    public let createdAt: Date?

    let fileData: Data
}
