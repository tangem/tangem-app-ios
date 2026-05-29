//
//  FeeProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.EthereumAccountOverride

public typealias ExpressFeeProvider = FeeProvider

public protocol FeeProvider {
    func feeCurrency() -> ExpressWalletCurrency
    func feeCurrencyBalance() throws -> Decimal

    func estimatedFee(amount: Decimal) async throws -> BSDKFee
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee
    func transactionFee(approveData: BSDKApproveTransactionData) async throws -> BSDKFee
    func transactionFee(data: ExpressTransactionDataType) async throws -> BSDKFee

    /// EVM-only override-aware variant: estimates fee assuming the spender has unlimited allowance during simulation.
    /// Default impl ignores `stateOverride` and delegates to the regular `transactionFee(data:)`.
    func transactionFee(
        data: ExpressTransactionDataType,
        stateOverride: [String: EthereumAccountOverride]?
    ) async throws -> BSDKFee

    func revokeAndApproveTransactionFee(revokeData: BSDKApproveTransactionData) async throws -> RevokeAndApproveFee
}

public extension FeeProvider {
    func isFeeCurrency(source: ExpressWalletCurrency) -> Bool {
        source == feeCurrency()
    }

    func feeCurrencyHasPositiveBalance() throws -> Bool {
        try feeCurrencyBalance() > .zero
    }

    /// Default fallback: providers that don't honor `stateOverride` will silently degrade — the caller's
    /// V2 attempt fails (allowance still missing in simulation) and the higher layer falls back to legacy.
    func transactionFee(
        data: ExpressTransactionDataType,
        stateOverride: [String: EthereumAccountOverride]?
    ) async throws -> BSDKFee {
        try await transactionFee(data: data)
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
