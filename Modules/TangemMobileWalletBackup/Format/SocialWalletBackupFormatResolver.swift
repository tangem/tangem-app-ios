//
//  SocialWalletBackupFormatResolver.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Protocols

protocol SocialWalletBackupFormatResolvable {
    func resolve(_ resolver: SocialWalletBackupFormatResolver) -> any SocialWalletBackupFormat
}

protocol SocialWalletBackupFormatResolver: Sendable {
    func resolveV1() -> any SocialWalletBackupFormat
}

// MARK: - Resolver

struct CommonSocialWalletBackupFormatResolver: SocialWalletBackupFormatResolver {
    func resolveV1() -> any SocialWalletBackupFormat {
        SocialWalletBackupFormatV1()
    }
}

// MARK: - SocialWalletBackupFormatVersion + SocialWalletBackupFormatResolvable

extension SocialWalletBackupFormatVersion: SocialWalletBackupFormatResolvable {
    func resolve(_ resolver: SocialWalletBackupFormatResolver) -> any SocialWalletBackupFormat {
        switch self {
        case .v1: resolver.resolveV1()
        }
    }
}
