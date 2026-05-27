//
//  Alephium+LockScript.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A protocol representing a lockup script in the Alephium blockchain
    protocol LockupScript {
        /// The script hint for the lockup script
        var scriptHint: ScriptHint { get }
    }
}
