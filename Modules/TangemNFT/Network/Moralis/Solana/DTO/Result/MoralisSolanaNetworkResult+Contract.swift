//
//  MoralisSolanaNetworkResult+Contract.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension MoralisSolanaNetworkResult {
    struct Contract: Decodable {
        let type: String?
        let name: String?
        let symbol: String?
    }
}
