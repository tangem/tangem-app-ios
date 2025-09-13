//
//  CryptoAccountsETagStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol CryptoAccountsETagStorage {
    func loadETag(for userWalletId: UserWalletId) -> String?
    func saveETag(_ eTag: String, for userWalletId: UserWalletId)
}
