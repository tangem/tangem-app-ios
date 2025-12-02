//
//  P2PDTO+AccountSummary.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension P2PDTO {
    enum AccountSummary {
        typealias Response = GenericResponse<AccountSummaryInfo>

        struct AccountSummaryInfo: Decodable {
            let delegatorAddress: String
            let vaultAddress: String
            let stake: StakeInfo
            @FlexibleDecimal var availableToUnstake: Decimal?
            @FlexibleDecimal var availableToWithdraw: Decimal?
            let exitQueue: ExitQueue
        }

        struct StakeInfo: Decodable {
            @FlexibleDecimal var assets: Decimal?
            @FlexibleDecimal var totalEarnedAssets: Decimal?
        }

        struct ExitQueue: Decodable {
            @FlexibleDecimal var total: Decimal?
            let requests: [ExitRequest]
        }

        struct ExitRequest: Decodable {
            let ticket: String
            @FlexibleDecimal var totalAssets: Decimal?
            let timestamp: Double
            let withdrawalTimestamp: Double?
            let isClaimable: Bool
        }
    }
}
