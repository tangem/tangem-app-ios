//
//  ALPH+AssetOutputInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A struct representing the information about an asset output in the Alephium blockchain
    /// It contains details about the reference to the output, the output itself, and the type of the output
    struct AssetOutputInfo {
        /// The reference to the output
        let ref: AssetOutputRef

        /// The output itself
        let output: AssetOutput

        /// The type of the output
        let outputType: OutputType
    }
}
