//
//  YieldModuleBottomSheetParams.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

enum YieldModuleBottomSheetParams {
    struct StartEarningParams: Equatable {
        let tokenName: String
        let tokenIcon: Image
        let networkFee: String
        let maximumFee: String
        let blockchainName: String
    }

    struct RateInfoParams: Equatable {
        let lastYearReturns: [String: Double]
    }

    struct FeePolicyParams: Equatable {
        let tokenName: String
        let networkFee: String
        let maximumFee: String
        let blockchainName: String
    }

    struct EarnInfoParams: Equatable {
        let earningsData: EarningsData
        let status: String
        let apy: String
        let availableFunds: AvailableFundsData
        let transferMode: String
        let tokenName: String
        let tokenSymbol: String

        @IgnoredEquatable var onReadMoreAction: () -> Void
        @IgnoredEquatable var onStopEarningAction: () -> Void

        struct AvailableFundsData: Identifiable, Equatable {
            let availableBalance: String

            var id: String {
                availableBalance.hashValue.description
            }
        }

        struct EarningsData: Identifiable, Equatable {
            let totalEarnings: String
            let chartData: [String: Double]

            var id: String {
                totalEarnings.hashValue.description + chartData.description.hashValue.description
            }
        }
    }
}
