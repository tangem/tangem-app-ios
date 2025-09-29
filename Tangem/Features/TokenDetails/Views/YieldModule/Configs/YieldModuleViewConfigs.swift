//
//  YieldModuleViewConfigs.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemAssets

enum YieldModuleViewConfigs {
    struct BalanceInfoParams: Equatable {
        let tokenItem: TokenItem
    }

    enum YieldModuleNotificationBannerParams {
        case notEnoughFeeCurrency(feeCurrencyName: String, tokenIcon: ImageType, buttonAction: @MainActor @Sendable () -> Void)
        case approveNeeded(buttonAction: @MainActor @Sendable () -> Void)
    }

    struct CommonParams: Equatable {
        let tokenName: String
        let networkFee: String
        let readMoreUrl: URL

        @IgnoredEquatable var mainAction: @MainActor @Sendable () -> Void
    }

    struct StartEarningParams: Equatable {
        let tokenName: String
        let tokenId: String?
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
        let status: Status
        let apy: String
        let availableFunds: AvailableFundsData
        let transferMode: String
        let tokenName: String
        let tokenSymbol: String
        let readMoreUrl: URL

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

        enum Status: Equatable {
            case active(approveRequired: Bool)
            case paused

            var description: String {
                switch self {
                case .active:
                    Localization.yieldModuleStatusActive
                case .paused:
                    Localization.yieldModuleStatusPaused
                }
            }
        }
    }
}
