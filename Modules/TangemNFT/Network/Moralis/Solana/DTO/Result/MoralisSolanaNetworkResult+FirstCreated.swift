//
//  MoralisSolanaNetworkResult+FirstCreated.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension MoralisSolanaNetworkResult {
    struct FirstCreated: Decodable {
        let mintTimestamp: Int?
        let mintBlockNumber: Int?
        let mintTransaction: String?
    }
}
