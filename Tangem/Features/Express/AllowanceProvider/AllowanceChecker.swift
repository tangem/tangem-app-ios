//
//  AllowanceChecker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct AllowanceChecker {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let walletAddress: String
    private let ethereumNetworkProvider: EthereumNetworkProvider?
    private let ethereumTransactionDataBuilder: EthereumTransactionDataBuilder?

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        walletAddress: String,
        ethereumNetworkProvider: EthereumNetworkProvider?,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder?
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.walletAddress = walletAddress
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.ethereumTransactionDataBuilder = ethereumTransactionDataBuilder
    }

    func isPermissionRequired(amount: Decimal, spender: String) async throws -> Bool {
        guard let contract = tokenItem.contractAddress else {
            throw AllowanceCheckerError.contractAddressNotFound
        }

        var allowance = try await getAllowance(owner: walletAddress, to: spender, contract: contract)
        allowance /= tokenItem.decimalValue
        AppLogger.info("\(tokenItem.name) allowance - \(allowance)")

        // If we don't have enough allowance
        guard allowance < amount else {
            return false
        }

        return true
    }

    func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal {
        guard let ethereumNetworkProvider = ethereumNetworkProvider else {
            throw AllowanceCheckerError.ethereumNetworkProviderNotFound
        }

        let allowance = try await ethereumNetworkProvider
            .getAllowance(owner: owner, spender: spender, contractAddress: contract)
            .async()

        return allowance
    }

    func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) async throws -> ApproveTransactionData {
        guard let ethereumTransactionDataBuilder = ethereumTransactionDataBuilder else {
            throw AllowanceCheckerError.ethereumTransactionDataBuilderNotFound
        }

        guard let ethereumNetworkProvider = ethereumNetworkProvider else {
            throw AllowanceCheckerError.ethereumNetworkProviderNotFound
        }

        guard let contract = tokenItem.contractAddress else {
            throw AllowanceCheckerError.contractAddressNotFound
        }

        let approveAmount: Decimal = switch policy {
        case .specified: amount * tokenItem.decimalValue
        case .unlimited: .greatestFiniteMagnitude
        }

        let data = try ethereumTransactionDataBuilder.buildForApprove(spender: spender, amount: approveAmount)
        let amount = BSDKAmount(
            with: feeTokenItem.blockchain,
            type: feeTokenItem.amountType,
            value: 0
        )

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

enum AllowanceCheckerError: String, Hashable, LocalizedError {
    case contractAddressNotFound
    case ethereumNetworkProviderNotFound
    case ethereumTransactionDataBuilderNotFound
    case approveFeeNotFound
}
