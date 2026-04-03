//
//  FeeProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public typealias ExpressFeeProvider = FeeProvider

public protocol FeeProvider {
    func feeCurrency() -> ExpressWalletCurrency
    func feeCurrencyBalance() throws -> Decimal

    func estimatedFee(amount: Decimal) async throws -> BSDKFee
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee
    func transactionFee(approveData: BSDKApproveTransactionData) async throws -> BSDKFee
    func transactionFee(data: ExpressTransactionDataType) async throws -> BSDKFee
}

public extension FeeProvider {
    func isFeeCurrency(source: ExpressWalletCurrency) -> Bool {
        source == feeCurrency()
    }

    func feeCurrencyHasPositiveBalance() throws -> Bool {
        try feeCurrencyBalance() > .zero
    }

    /// Estimates fees for a revoke+approve flow.
    /// The node can't simulate a non-zero approve when on-chain allowance is already non-zero
    /// (USDT reverts), so both fees are derived from the revoke tx estimate:
    /// - `unit`: 1x revoke fee (used for the revoke tx and as a base for the approve tx)
    /// - `total`: 3x (revoke@1x + approve@~2x), used for balance validation and UI display
    func revokeAndApproveTransactionFee(revokeData: BSDKApproveTransactionData) async throws -> RevokeAndApproveFee {
        let unit = try await transactionFee(approveData: revokeData)
        var totalAmount = unit.amount
        totalAmount.value *= FeeProviderConstants.revokeAndApproveFeeMultiplier
        let total = BSDKFee(totalAmount, parameters: unit.parameters)
        return RevokeAndApproveFee(unit: unit, total: total)
    }
}

private enum FeeProviderConstants {
    /// revoke@1x + approve@~2x = 3x total
    static let revokeAndApproveFeeMultiplier: Decimal = 3
}

public struct RevokeAndApproveFee {
    /// Single revoke tx fee estimate (1x)
    public let unit: BSDKFee
    /// Total fee for the entire flow: revoke + approve (3x)
    public let total: BSDKFee
}
