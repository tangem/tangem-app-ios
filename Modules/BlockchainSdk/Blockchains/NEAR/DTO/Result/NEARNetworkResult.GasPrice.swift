//
//  NEARNetworkResult.GasPrice.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension NEARNetworkResult {
    struct GasPrice: Decodable {
        let gasPrice: String
    }
}
