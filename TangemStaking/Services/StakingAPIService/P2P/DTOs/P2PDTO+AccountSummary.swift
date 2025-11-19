//
//  P2PDTO+AccountSummary.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension P2PDTO {
    enum AccountSummary {
        typealias Response = GenericResponse<AccountSummaryInfo>

        struct AccountSummaryInfo: Decodable {
            let delegatorAddress: String
            let vaultAddress: String
            let stake: StakeInfo
            let availableToUnstake: Decimal
            let availableToWithdraw: Decimal
            let exitQueue: ExitQueue
        }

        struct StakeInfo: Decodable {
            let assets: Decimal
            let totalEarnedAssets: Decimal
        }

        struct ExitQueue: Decodable {
            let total: Decimal
            let requests: [ExitRequest]
        }

        struct ExitRequest: Decodable {
            let ticket: String
            let totalAssets: Decimal
            let timestamp: Double
            let withdrawalTimestamp: Double
            let isClaimable: Bool
        }
    }
}
