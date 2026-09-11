//
//  WalletBackupFormatResolver.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Protocols

protocol WalletBackupFormatResolvable {
    func resolve(_ resolver: WalletBackupFormatResolver) -> any WalletBackupFormat
}

protocol WalletBackupFormatResolver: Sendable {
    func resolveV1() -> any WalletBackupFormat
}

// MARK: - Resolver

struct CommonWalletBackupFormatResolver: WalletBackupFormatResolver {
    func resolveV1() -> any WalletBackupFormat {
        WalletBackupFormatV1()
    }
}

// MARK: - WalletBackupFormatVersion + WalletBackupFormatResolvable

extension WalletBackupFormatVersion: WalletBackupFormatResolvable {
    func resolve(_ resolver: WalletBackupFormatResolver) -> any WalletBackupFormat {
        switch self {
        case .v1: resolver.resolveV1()
        }
    }
}
