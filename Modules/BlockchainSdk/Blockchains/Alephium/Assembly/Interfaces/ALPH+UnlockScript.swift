//
//  ALPH+UnlockScript.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A protocol representing an unlock script in the Alephium blockchain
    protocol UnlockScript {
        /// The public key data for the unlock script
        var publicKeyData: Data { get }
    }
}
