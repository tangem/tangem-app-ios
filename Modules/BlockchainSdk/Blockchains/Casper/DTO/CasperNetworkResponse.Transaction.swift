//
//  CasperNetworkResponse.Transaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension CasperNetworkResponse {
    /// The balance represented in motes.
    struct Transaction: Decodable {
        let deployHash: String
    }
}
