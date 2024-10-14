//
//  NEARNetworkParams.Transaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension NEARNetworkParams {
    struct Transaction: Encodable {
        /// The payload string has a Base64 encoding.
        let payload: String

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(payload)
        }
    }
}
