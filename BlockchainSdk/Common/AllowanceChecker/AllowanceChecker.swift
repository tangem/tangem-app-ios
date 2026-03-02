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
    private let ethereumNetworkProvider: EthereumNetworkProvider?
    private let ethereumTransactionDataBuilder: EthereumTransactionDataBuilder?
    private let gaslessTransactionFeeProvider: (any GaslessTransactionFeeProvider)?

    public init(
        blockchain: Blockchain,
        amountType: Amount.AmountType,
        walletAddress: String,
        ethereumNetworkProvider: EthereumNetworkProvider?,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder?,
        gaslessTransactionFeeProvider: (any GaslessTransactionFeeProvider)? = nil
    ) {
        self.blockchain = blockchain
        self.amountType = amountType
        self.walletAddress = walletAddress
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.ethereumTransactionDataBuilder = ethereumTransactionDataBuilder
        self.gaslessTransactionFeeProvider = gaslessTransactionFeeProvider
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
        guard let ethereumNetworkProvider = ethereumNetworkProvider else {
            throw AllowanceCheckerError.ethereumNetworkProviderNotFound
        }

        let allowance = try await ethereumNetworkProvider
            .getAllowance(owner: owner, spender: spender, contractAddress: contract)
            .async()

        return allowance
    }

    public func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) async throws -> ApproveTransactionData {
        guard let ethereumNetworkProvider = ethereumNetworkProvider else {
            throw AllowanceCheckerError.ethereumNetworkProviderNotFound
        }

        let (data, contract) = try buildApproveCalldata(spender: spender, amount: amount, policy: policy)
        let zeroAmount = Amount(with: blockchain, type: .coin, value: 0)

        let fee = try await ethereumNetworkProvider
            .getFee(destination: contract, value: zeroAmount.encodedForSend, data: data)
            .async()

        guard let fee = fee[safe: 2] else {
            throw AllowanceCheckerError.approveFeeNotFound
        }

        return .init(txData: data, spender: spender, toContractAddress: contract, fee: fee)
    }

    public func makeGaslessApproveData(
        spender: String,
        amount: Decimal,
        policy: ApprovePolicy,
        feeToken: Token,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> ApproveTransactionData {
        guard let gaslessTransactionFeeProvider else {
            throw AllowanceCheckerError.gaslessTransactionFeeProviderNotFound
        }

        let (data, contract) = try buildApproveCalldata(spender: spender, amount: amount, policy: policy)

        let fee = try await gaslessTransactionFeeProvider.getGaslessApproveFee(
            feeToken: feeToken,
            approveData: data,
            contractAddress: contract,
            feeRecipientAddress: feeRecipientAddress,
            nativeToFeeTokenRate: nativeToFeeTokenRate
        )

        return .init(txData: data, spender: spender, toContractAddress: contract, fee: fee)
    }

    private func buildApproveCalldata(spender: String, amount: Decimal, policy: ApprovePolicy) throws -> (data: Data, contract: String) {
        guard let ethereumTransactionDataBuilder else {
            throw AllowanceCheckerError.ethereumTransactionDataBuilderNotFound
        }

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
    case ethereumNetworkProviderNotFound
    case ethereumTransactionDataBuilderNotFound
    case gaslessTransactionFeeProviderNotFound
    case approveFeeNotFound
    case wrongAmountType

    public var errorDescription: String? {
        switch self {
        case .contractAddressNotFound: "Contract address not found."
        case .ethereumNetworkProviderNotFound: "Ethereum network provider not found."
        case .ethereumTransactionDataBuilderNotFound: "Ethereum transaction data builder not found."
        case .gaslessTransactionFeeProviderNotFound: "Gasless transaction fee provider not found."
        case .approveFeeNotFound: "Approve fee not found."
        case .wrongAmountType: "Wrong amount type."
        }
    }
}
