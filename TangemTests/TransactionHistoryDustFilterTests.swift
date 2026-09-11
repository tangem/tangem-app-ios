//
//  TransactionHistoryDustFilterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("TransactionHistoryDustFilter")
struct TransactionHistoryDustFilterTests {
    /// 100 USD per token, with amounts picked so that `amount * usdRate` is an exact number of cents.
    private let usdRate = Decimal(100)
    /// 0.009 USD
    private let belowThreshold = Decimal(9) / Decimal(100_000)
    /// 0.01 USD
    private let atThreshold = Decimal(1) / Decimal(10_000)
    /// 0.02 USD
    private let aboveThreshold = Decimal(2) / Decimal(10_000)

    // MARK: - Filtering scope

    @Test(arguments: anyDirectionTypes, [true, false])
    func transferBelowThresholdIsDustWhicheverWayItMoved(
        type: TransactionViewModel.TransactionType,
        isOutgoing: Bool
    ) {
        let filter = TransactionHistoryDustFilter(usdRate: usdRate)

        #expect(filter.isDust(amount: belowThreshold, isOutgoing: isOutgoing, transactionType: type))
    }

    @Test(arguments: incomingOnlyTypes)
    func incomingOperationBelowThresholdIsDust(type: TransactionViewModel.TransactionType) {
        let filter = TransactionHistoryDustFilter(usdRate: usdRate)

        #expect(filter.isDust(amount: belowThreshold, isOutgoing: false, transactionType: type))
    }

    @Test(arguments: incomingOnlyTypes)
    func outgoingOperationIsShownHoweverSmall(type: TransactionViewModel.TransactionType) {
        let filter = TransactionHistoryDustFilter(usdRate: usdRate)

        #expect(!filter.isDust(amount: belowThreshold, isOutgoing: true, transactionType: type))
        #expect(!filter.isDust(amount: .zero, isOutgoing: true, transactionType: type))
    }

    @Test(arguments: neverFilteredTypes, [true, false])
    func operationOutsideTheScopeIsNeverDust(
        type: TransactionViewModel.TransactionType,
        isOutgoing: Bool
    ) {
        let filter = TransactionHistoryDustFilter(usdRate: usdRate)

        #expect(!filter.isDust(amount: belowThreshold, isOutgoing: isOutgoing, transactionType: type))
        #expect(!filter.isDust(amount: .zero, isOutgoing: isOutgoing, transactionType: type))
    }

    // MARK: - Threshold

    @Test(arguments: [true, false])
    func transferWorthExactlyTheThresholdIsShown(isOutgoing: Bool) {
        let filter = TransactionHistoryDustFilter(usdRate: usdRate)

        #expect(!filter.isDust(amount: atThreshold, isOutgoing: isOutgoing, transactionType: .transfer))
    }

    @Test(arguments: [true, false])
    func transferAboveTheThresholdIsShown(isOutgoing: Bool) {
        let filter = TransactionHistoryDustFilter(usdRate: usdRate)

        #expect(!filter.isDust(amount: aboveThreshold, isOutgoing: isOutgoing, transactionType: .transfer))
    }

    @Test
    func zeroAmountTransferIsDust() {
        let filter = TransactionHistoryDustFilter(usdRate: usdRate)

        #expect(filter.isDust(amount: .zero, isOutgoing: true, transactionType: .transfer))
    }

    @Test
    func negativeAmountIsComparedByMagnitude() {
        let filter = TransactionHistoryDustFilter(usdRate: usdRate)

        #expect(filter.isDust(amount: -belowThreshold, isOutgoing: true, transactionType: .transfer))
        #expect(!filter.isDust(amount: -aboveThreshold, isOutgoing: true, transactionType: .transfer))
    }

    // MARK: - Unusable rates

    @Test(arguments: anyDirectionTypes + incomingOnlyTypes)
    func missingRateDisablesFiltering(type: TransactionViewModel.TransactionType) {
        let filter = TransactionHistoryDustFilter(usdRate: nil)

        #expect(!filter.isDust(amount: belowThreshold, isOutgoing: false, transactionType: type))
    }

    @Test(arguments: [Decimal.zero, Decimal(-1)])
    func nonPositiveRateDisablesFiltering(rate: Decimal) {
        let filter = TransactionHistoryDustFilter(usdRate: rate)

        #expect(!filter.isDust(amount: belowThreshold, isOutgoing: false, transactionType: .transfer))
        #expect(!filter.isDust(amount: aboveThreshold, isOutgoing: false, transactionType: .transfer))
    }

    // MARK: - Test arguments

    private static var anyDirectionTypes: [TransactionViewModel.TransactionType] {
        // Did you get a compilation error here? If so, add your new transaction type to one of the three lists
        // below: `anyDirectionTypes` if the threshold applies whichever way the funds moved, `incomingOnlyTypes`
        // if only received dust should be hidden, `neverFilteredTypes` if the threshold must not apply at all
        switch TransactionViewModel.TransactionType.transfer {
        case .transfer: break
        case .gaslessTransfer: break
        case .stake: break
        case .unstake: break
        case .withdraw: break
        case .claimRewards: break
        case .yieldEnter: break
        case .yieldEnterCoin: break
        case .yieldTopup: break
        case .yieldWithdraw: break
        case .yieldWithdrawCoin: break
        case .yieldSend: break
        case .yieldDeploy: break
        case .yieldInit: break
        case .yieldReactivate: break
        case .approve: break
        case .swap: break
        case .onramp: break
        case .vote: break
        case .restake: break
        case .gaslessTransactionFee: break
        case .operation: break
        case .unknownOperation: break
        case .tangemPay: break
        }

        return [
            .transfer,
            .gaslessTransfer,
        ]
    }

    private static var incomingOnlyTypes: [TransactionViewModel.TransactionType] {
        [
            .stake,
            .unstake,
            .withdraw,
            .claimRewards,
            .yieldEnter,
            .yieldEnterCoin,
            .yieldTopup,
            .yieldWithdraw,
            .yieldWithdrawCoin,
            .yieldSend,
        ]
    }

    private static var neverFilteredTypes: [TransactionViewModel.TransactionType] {
        [
            .yieldDeploy,
            .yieldInit,
            .yieldReactivate,
            .approve,
            .swap,
            .onramp,
            .vote,
            .restake,
            .gaslessTransactionFee,
            .operation(name: "Mint"),
            .unknownOperation,
            .tangemPay(.transfer(name: "Tangem Pay")),
            .tangemPay(.fee(name: "Service fee")),
            .tangemPay(.spend(name: "Coffee", icon: nil, isDeclined: false, isNegativeAmount: true)),
        ]
    }
}
