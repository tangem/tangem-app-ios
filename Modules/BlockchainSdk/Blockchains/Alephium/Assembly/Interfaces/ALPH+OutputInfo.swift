//
//  ALPH+OutputInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A protocol representing output information in the Alephium blockchain
    protocol OutputInfo {
        /// The reference to the asset output
        var ref: AssetOutputRef { get }
        /// The output information
        var output: TxOutput { get }
    }
}
