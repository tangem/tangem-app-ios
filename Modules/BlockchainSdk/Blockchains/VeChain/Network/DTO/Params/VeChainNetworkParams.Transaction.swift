//
//  VeChainNetworkParams.Transaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension VeChainNetworkParams {
    struct Transaction: Encodable {
        /// A hex form of encoded transaction.
        let raw: String
    }
}
