//
//  YieldModuleParams.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemLocalization

enum YieldModuleParams {
    struct BalanceInfoParams: Equatable {
        let tokenName: String
        let tokenImageUrl: URL?
    }

    enum YieldModuleBottomSheetNotificationBannerParams {
        case notEnoughFeeCurrency(feeCurrencyName: String, tokenIcon: Image, buttonAction: @MainActor @Sendable () -> Void)
        case approveNeeded(buttonAction: @MainActor @Sendable () -> Void)
    }

    struct FeeCurrencyInfo: Equatable {
        let feeCurrencyName: String
        let feeCurrencyIcon: Image
        let feeCurrencySymbol: String
        @IgnoredEquatable var goToFeeCurrencyAction: @MainActor @Sendable () -> Void
    }

    struct СommonParams: Equatable {
        let tokenName: String
        let networkFee: String
        let feeCurrencyInfo: FeeCurrencyInfo?

        @IgnoredEquatable var readMoreAction: @MainActor @Sendable () -> Void
        @IgnoredEquatable var mainAction: @MainActor @Sendable () -> Void
    }

    struct StartEarningParams: Equatable {
        let tokenName: String
        let tokenImageUrl: URL?
        let networkFee: String
        let maximumFee: String
        let blockchainName: String
        let feeCurrencyInfo: FeeCurrencyInfo?
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
        let networkFee: String

        let feeCurrencyInfo: FeeCurrencyInfo?

        @IgnoredEquatable var onReadMoreAction: @MainActor @Sendable () -> Void
        @IgnoredEquatable var onStopEarningAction: @MainActor @Sendable () -> Void
        @IgnoredEquatable var onApproveAction: @MainActor @Sendable () -> Void

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
