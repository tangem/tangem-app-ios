//
//  SocialWalletBackupFormatVersion.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum SocialWalletBackupFormatVersion: Int, Codable {
    case v1 = 1
}

extension SocialWalletBackupFormatVersion {
    static let current: SocialWalletBackupFormatVersion = .v1
}
