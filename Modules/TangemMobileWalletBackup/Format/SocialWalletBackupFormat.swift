//
//  SocialWalletBackupFormat.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol SocialWalletBackupFormat: Sendable {
    associatedtype File: Codable

    func makeFile(payload: any WalletBackupPayload, walletId: String, key: Data) throws -> File

    func backup(from fileData: Data) throws -> MobileWalletSocialBackup

    func payload(from fileData: Data, key: Data) throws -> any WalletBackupPayload
}
