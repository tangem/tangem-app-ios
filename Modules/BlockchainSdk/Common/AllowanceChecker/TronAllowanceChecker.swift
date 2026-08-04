//
//  TronAllowanceChecker.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct TronAllowanceChecker: AllowanceChecking {
    /// Tron nodes can't estimate fees with an allowance state override.
    public var supportsOneTapApprove: Bool { false }

    private let blockchain: Blockchain
    private let amountType: Amount.AmountType
    private let walletAddress: String
    private let allowanceProvider: TronAllowanceProvider
    private let transactionDataBuilder: TronTransactionDataBuilder

    public init(
        blockchain: Blockchain,
        amountType: Amount.AmountType,
        walletAddress: String,
        allowanceProvider: TronAllowanceProvider,
        transactionDataBuilder: TronTransactionDataBuilder
    ) {
        self.blockchain = blockchain
        self.amountType = amountType
        self.walletAddress = walletAddress
        self.allowanceProvider = allowanceProvider
        self.transactionDataBuilder = transactionDataBuilder
    }

    public func allowanceState(
        amount: Decimal,
        spender: String,
        policy: ApprovePolicy
    ) async throws -> AllowanceCheckerResult {
        guard let token = amountType.token else {
            throw AllowanceCheckerError.contractAddressNotFound
        }

        let rawAllowance = try await allowanceProvider
            .getAllowance(owner: walletAddress, spender: spender, contractAddress: token.contractAddress)
            .async()

        let normalizedAllowance = rawAllowance / token.decimalValue
        BSDKLogger.info("\(token.name) allowance - \(normalizedAllowance)")

        guard normalizedAllowance < amount else {
            return .enoughAllowance
        }

        // TRC20 has no USDT-on-Ethereum reset-to-zero restriction — a plain approve is always sufficient.
        return .approveRequired(try makeApproveData(spender: spender, amount: amount, policy: policy))
    }

    public func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) throws -> ApproveTransactionData {
        guard let token = amountType.token else {
            throw AllowanceCheckerError.contractAddressNotFound
        }

        let approveValue: Decimal = switch policy {
        case .specified: amount
        // `Amount.bigUIntValue` encodes `greatestFiniteMagnitude` as `2^256 - 1`
        case .unlimited: .greatestFiniteMagnitude
        }

        let approveAmount = Amount(with: blockchain, type: amountType, value: approveValue)
        let txData = try transactionDataBuilder.buildForApprove(spender: spender, amount: approveAmount)

        return ApproveTransactionData(txData: txData, spender: spender, toContractAddress: token.contractAddress)
    }
}
