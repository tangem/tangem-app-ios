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
    var isGaslessFeeSelected: Bool { get }

    func feeCurrency() -> ExpressWalletCurrency
    func feeCurrencyBalance() throws -> Decimal

    func estimatedFee(amount: Decimal) async throws -> BSDKFee
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee
    func transactionFee(approveData: BSDKApproveTransactionData) async throws -> BSDKFee
    func transactionFee(data: ExpressTransactionDataType) async throws -> BSDKFee
    func revokeAndApproveTransactionFee(revokeData: BSDKApproveTransactionData) async throws -> RevokeAndApproveFee
    func transactionFee(
        data: ExpressTransactionDataType,
        allowanceOverride: AllowanceOverride,
        approveData: BSDKApproveTransactionData
    ) async throws -> ApproveWithSwapFee
}

public extension FeeProvider {
    var isGaslessFeeSelected: Bool { false }

    func isFeeCurrency(source: ExpressWalletCurrency) -> Bool {
        source == feeCurrency()
    }

    func feeCurrencyHasPositiveBalance() throws -> Bool {
        try feeCurrencyBalance() > .zero
    }

    func transactionFee(
        data: ExpressTransactionDataType,
        allowanceOverride: AllowanceOverride,
        approveData: BSDKApproveTransactionData
    ) async throws -> ApproveWithSwapFee {
        throw ExpressProviderError.transactionDataNotFound
    }
}

public struct ApproveWithSwapFee {
    /// Combined approve+swap fee — what the user sees and what validation runs against.
    public let total: BSDKFee
    /// Approve component with its own gas parameters — used to build the approve tx at send.
    public let approve: BSDKFee

    public init(total: BSDKFee, approve: BSDKFee) {
        self.total = total
        self.approve = approve
    }
}

public struct AllowanceOverride {
    public let tokenContractAddress: String
    public let owner: String
    public let spender: String

    public init(tokenContractAddress: String, owner: String, spender: String) {
        self.tokenContractAddress = tokenContractAddress
        self.owner = owner
        self.spender = spender
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
