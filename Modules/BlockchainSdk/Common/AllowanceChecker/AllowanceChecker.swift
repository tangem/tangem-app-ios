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
    private let ethereumNetworkProvider: EthereumNetworkProvider?
    private let ethereumTransactionDataBuilder: EthereumTransactionDataBuilder?

    public init(
        blockchain: Blockchain,
        amountType: Amount.AmountType,
        walletAddress: String,
        ethereumNetworkProvider: EthereumNetworkProvider?,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder?
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
        allowance /= blockchain.decimalValue
        BSDKLogger.info("\(amountType.token?.name as Any) allowance - \(allowance)")

        // If we don't have enough allowance
        guard allowance < amount else {
            return false
        }

        return true
    }

    public func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal {
        guard let ethereumNetworkProvider = ethereumNetworkProvider else {
            throw AllowanceCheckerError.ethereumNetworkProviderNotFound
        }

        let allowance = try await ethereumNetworkProvider
            .getAllowance(owner: owner, spender: spender, contractAddress: contract)
            .async()

        return allowance
    }

    public func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) async throws -> ApproveTransactionData {
        guard let ethereumTransactionDataBuilder = ethereumTransactionDataBuilder else {
            throw AllowanceCheckerError.ethereumTransactionDataBuilderNotFound
        }

        guard let ethereumNetworkProvider = ethereumNetworkProvider else {
            throw AllowanceCheckerError.ethereumNetworkProviderNotFound
        }

        guard let contract = amountType.token?.contractAddress else {
            throw AllowanceCheckerError.contractAddressNotFound
        }

        let approveAmount: Decimal = switch policy {
        case .specified: amount * blockchain.decimalValue
        case .unlimited: .greatestFiniteMagnitude
        }

        let data = try ethereumTransactionDataBuilder.buildForApprove(spender: spender, amount: approveAmount)
        let amount = Amount(with: blockchain, type: .coin, value: 0)

        let fee = try await ethereumNetworkProvider
            .getFee(destination: contract, value: amount.encodedForSend, data: data)
            .async()

        // Use fastest
        guard let fee = fee[safe: 2] else {
            throw AllowanceCheckerError.approveFeeNotFound
        }

        return .init(txData: data, spender: spender, toContractAddress: contract, fee: fee)
    }
}

public enum AllowanceCheckerError: String, Hashable, LocalizedError {
    case contractAddressNotFound
    case ethereumNetworkProviderNotFound
    case ethereumTransactionDataBuilderNotFound
    case approveFeeNotFound

    public var errorDescription: String? {
        switch self {
        case .contractAddressNotFound: "Contract address not found."
        case .ethereumNetworkProviderNotFound: "Ethereum network provider not found."
        case .ethereumTransactionDataBuilderNotFound: "Ethereum transaction data builder not found."
        case .approveFeeNotFound: "Approve fee not found."
        }
    }
}
