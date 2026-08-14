//
//  CryptoAccountsRemoteState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CryptoAccountsRemoteState {
    /// Index for the derivation path to be used when creating a new crypto account.
    let nextCryptoDerivationIndex: Int
    /// Index for the derivation path to be used when creating a new joint account, counted apart from the crypto one.
    /// - Note: Nil until the endpoint counts the types apart, since nothing else knows how many joint accounts a
    /// wallet has.
    let nextJointDerivationIndex: Int?
    let accounts: [StoredCryptoAccount]
}
