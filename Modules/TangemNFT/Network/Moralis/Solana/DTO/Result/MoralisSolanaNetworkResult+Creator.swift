//
//  MoralisSolanaNetworkResult+Creator.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension MoralisSolanaNetworkResult {
    struct Creator: Decodable {
        let address: String?
        let share: Int?
        let verified: Bool?
    }
}
