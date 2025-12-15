//
//  P2PDTO+RewardsHistory.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension P2PDTO {
    enum RewardsHistory {
        typealias Response = GenericResponse<RewardsHistoryInfo>

        struct RewardsHistoryInfo: Decodable {
            let delegatorAddress: String
            let vaultAddress: String
            let rewards: [RewardEntry]
        }

        struct RewardEntry: Decodable {
            let date: Date
            let apy: Decimal
            let balance: Decimal
            let rewards: Decimal
        }
    }
}
