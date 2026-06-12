//
//  AddressBookSigning.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Signs address-entry digests with the wallet key. Cold wallets prompt for an NFC tap, hot wallets
/// prompt for a password — both transparently, through `TransactionSigner`.
protocol AddressBookSigning {
    /// Signs each 32-byte digest and returns the signatures in the same order. All digests are signed
    /// in a single operation, so the user is prompted only once per call.
    func sign(digests: [Data], walletPublicKey: Wallet.PublicKey) async throws -> [Data]
}
