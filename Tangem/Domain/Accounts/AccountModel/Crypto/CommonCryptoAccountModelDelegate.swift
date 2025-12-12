//
//  CommonCryptoAccountModelDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol CommonCryptoAccountModelDelegate: AnyObject {
    func commonCryptoAccountModel(
        _ model: CommonCryptoAccountModel,
        wantsToUpdateWith config: CryptoAccountPersistentConfig
    ) async throws(AccountEditError)

    func commonCryptoAccountModelWantsToArchive(
        _ model: CommonCryptoAccountModel
    ) async throws(AccountArchivationError)
}
