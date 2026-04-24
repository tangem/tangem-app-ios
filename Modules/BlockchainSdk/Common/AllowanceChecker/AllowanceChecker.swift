//
//  AllowanceChecker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct AllowanceChecker {
    private let blockchain: Blockchain
    private let amountType: Amount.AmountType
    private let walletAddress: String
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let ethereumTransactionDataBuilder: EthereumTransactionDataBuilder

    public init(
        blockchain: Blockchain,
        amountType: Amount.AmountType,
        walletAddress: String,
        ethereumNetworkProvider: EthereumNetworkProvider,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder,
    ) {
        self.blockchain = blockchain
        self.amountType = amountType
        self.walletAddress = walletAddress
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.ethereumTransactionDataBuilder = ethereumTransactionDataBuilder
    }

    public func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal {
        let allowance = try await ethereumNetworkProvider
            .getAllowance(owner: owner, spender: spender, contractAddress: contract)
            .async()

        return allowance
    }

    private func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) throws -> ApproveTransactionData {
        let (data, contract) = try buildApproveCalldata(spender: spender, amount: amount, policy: policy)
        return .init(txData: data, spender: spender, toContractAddress: contract)
    }

    /// Determines the full allowance state in a single call: whether approval is needed,
    /// and if so, whether a revoke-before-approve flow is required.
    public func allowanceState(
        amount: Decimal,
        spender: String,
        policy: ApprovePolicy
    ) async throws -> AllowanceCheckerResult {
        guard let contract = amountType.token?.contractAddress else {
            throw AllowanceCheckerError.contractAddressNotFound
        }

        let rawAllowance = try await getAllowance(owner: walletAddress, to: spender, contract: contract)
        let normalizedAllowance = rawAllowance / (try decimalValue())
        BSDKLogger.info("\(amountType.token?.name as Any) allowance - \(normalizedAllowance)")

        switch normalizedAllowance {
        case let allowance where allowance >= amount:
            return .enoughAllowance
        case let allowance where requiresRevokeBefore && allowance > 0:
            // Some ERC-20 tokens (notably USDT on Ethereum mainnet) require the current allowance
            // to be reset to zero before a new non-zero approval can be set.
            let revokeData = try makeApproveData(spender: spender, amount: .zero, policy: .specified)
            let approveData = try makeApproveData(spender: spender, amount: amount, policy: policy)
            BSDKLogger.info("Revoke required before approve — current allowance: \(rawAllowance), contract: \(contract)")
            return .revokeAndApproveRequired(revoke: revokeData, approve: approveData)
        default:
            let approveData = try makeApproveData(spender: spender, amount: amount, policy: policy)
            return .approveRequired(approveData)
        }
    }

    /// Whether this token requires revoking the existing allowance before setting a new one.
    /// Currently only USDT on Ethereum mainnet has this restriction.
    private var requiresRevokeBefore: Bool {
        guard case .ethereum(testnet: false) = blockchain else {
            return false
        }

        guard let contractAddress = amountType.token?.contractAddress else {
            return false
        }

        return contractAddress.caseInsensitiveCompare(Constants.ethereumUSDTContractAddress) == .orderedSame
    }

    private func buildApproveCalldata(spender: String, amount: Decimal, policy: ApprovePolicy) throws -> (data: Data, contract: String) {
        guard let contract = amountType.token?.contractAddress else {
            throw AllowanceCheckerError.contractAddressNotFound
        }

        let approveAmount: Decimal = switch policy {
        case .specified: try amount * decimalValue()
        case .unlimited: .greatestFiniteMagnitude
        }

        let data = try ethereumTransactionDataBuilder.buildForApprove(spender: spender, amount: approveAmount)
        return (data, contract)
    }

    private func decimalValue() throws -> Decimal {
        switch amountType {
        case .coin: blockchain.decimalValue
        case .token(let token): token.decimalValue
        case .feeResource, .reserve: throw AllowanceCheckerError.wrongAmountType
        }
    }
}

public enum AllowanceCheckerResult {
    case enoughAllowance
    case approveRequired(ApproveTransactionData)
    case revokeAndApproveRequired(revoke: ApproveTransactionData, approve: ApproveTransactionData)
}

public enum AllowanceCheckerError: String, Hashable, LocalizedError {
    case contractAddressNotFound
    case wrongAmountType

    public var errorDescription: String? {
        switch self {
        case .contractAddressNotFound: "Contract address not found."
        case .wrongAmountType: "Wrong amount type."
        }
    }
}

private extension AllowanceChecker {
    enum Constants {
        static let ethereumUSDTContractAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    }
}
