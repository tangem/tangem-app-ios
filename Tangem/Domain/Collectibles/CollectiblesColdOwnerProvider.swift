//
//  CollectiblesColdOwnerProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Resolves the account's own cold key. The vault PDA is a pure function of its public key, and cold operations
/// sign with it via the card — hence the full `Wallet.PublicKey`, not bare bytes. `nil` means never derived.
protocol CollectiblesColdOwnerProvider: AnyObject {
    func coldOwnerKey() -> Wallet.PublicKey?
}
