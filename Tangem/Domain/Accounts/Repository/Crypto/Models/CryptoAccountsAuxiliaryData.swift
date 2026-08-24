//
//  CryptoAccountsAuxiliaryData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CryptoAccountsAuxiliaryData {
    let archivedAccountsCount: Int
    /// - Note: Crypto accounts alone, since that is the counter the next derivation index of a new one comes from.
    let totalCryptoAccountsCount: Int
}
