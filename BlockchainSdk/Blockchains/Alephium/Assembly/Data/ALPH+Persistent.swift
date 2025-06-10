//
//  ALPH+Persistent.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A struct representing a persisted output in the Alephium blockchain
    /// It contains a cached level indicating the output's persistence level
    struct PersistedOutput: OutputType {
        var cachedLevel: Int = 0
    }

    /// A struct representing an unpersisted block output in the Alephium blockchain
    /// It contains a cached level indicating the output's persistence level
    struct UnpersistedBlockOutput: OutputType {
        var cachedLevel: Int = 1
    }

    /// A struct representing a mempool output in the Alephium blockchain
    /// It contains a cached level indicating the output's persistence level
    struct MemPoolOutput: OutputType {
        var cachedLevel: Int = 2
    }
}
