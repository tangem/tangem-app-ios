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
    func revokeAndApproveTransactionFee(revokeData: BSDKApproveTransactionData) async throws -> RevokeAndApproveFee
}

public extension FeeProvider {
    func isFeeCurrency(source: ExpressWalletCurrency) -> Bool {
        source == feeCurrency()
    }

    func feeCurrencyHasPositiveBalance() throws -> Bool {
        try feeCurrencyBalance() > .zero
    }
}

public struct RevokeAndApproveFee {
    /// Single revoke tx fee estimate (1x)
    public let unit: BSDKFee
    /// Total fee for the entire flow: revoke + approve (3x)
    public let total: BSDKFee

    public init(unit: BSDKFee, total: BSDKFee) {
        self.unit = unit
        self.total = total
    }
}
