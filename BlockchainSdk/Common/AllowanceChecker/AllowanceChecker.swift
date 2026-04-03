//
//  AllowanceChecker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

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

    public func isPermissionRequired(amount: Decimal, spender: String) async throws -> Bool {
        guard let contract = amountType.token?.contractAddress else {
            throw AllowanceCheckerError.contractAddressNotFound
        }

        var allowance = try await getAllowance(owner: walletAddress, to: spender, contract: contract)
        allowance /= try decimalValue()
        BSDKLogger.info("\(amountType.token?.name as Any) allowance - \(allowance)")

        // If we don't have enough allowance
        guard allowance < amount else {
            return false
        }

        return true
    }

    public func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal {
        let allowance = try await ethereumNetworkProvider
            .getAllowance(owner: owner, spender: spender, contractAddress: contract)
            .async()

        return allowance
    }

    public func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) throws -> ApproveTransactionData {
        let (data, contract) = try buildApproveCalldata(spender: spender, amount: amount, policy: policy)
        return .init(txData: data, spender: spender, toContractAddress: contract)
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
