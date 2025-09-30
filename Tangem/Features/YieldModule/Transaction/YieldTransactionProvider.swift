//
//  YieldTransactionProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt

final class YieldTransactionProvider {
    private let token: Token
    private let blockchain: Blockchain
    private let transactionCreator: TransactionCreator
    private let transactionBuilder: EthereumTransactionDataBuilder
    private let yieldSupplyContractAddresses: YieldSupplyContractAddresses
    private let maxNetworkFee: BigUInt

    init(
        token: Token,
        blockchain: Blockchain,
        transactionCreator: TransactionCreator,
        transactionBuilder: EthereumTransactionDataBuilder,
        yieldSupplyContractAddresses: YieldSupplyContractAddresses,
        maxNetworkFee: BigUInt
    ) {
        self.token = token
        self.blockchain = blockchain
        self.transactionCreator = transactionCreator
        self.transactionBuilder = transactionBuilder
        self.yieldSupplyContractAddresses = yieldSupplyContractAddresses
        self.maxNetworkFee = maxNetworkFee
    }

    // MARK: - Deploy

    func deployTransactions(
        walletAddress: String,
        tokenContractAddress: String,
        yieldContractAddress: String,
        fee: DeployEnterFee
    ) async throws -> [Transaction] {
        let deployTransaction = try await deployTransaction(
            walletAddress: walletAddress,
            tokenContractAddress: tokenContractAddress,
            fee: fee.deployFee
        )

        let approveTransaction = try await requestPermissionTransaction(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress,
            fee: fee.approveFee,
        )

        let enterResult = try await enterTransaction(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress,
            fee: fee.enterFee
        )

        return [deployTransaction, approveTransaction, enterResult]
    }

    // MARK: - Init

    func initTransactions(
        tokenContractAddress: String,
        yieldContractAddress: String,
        fee: InitEnterFee
    ) async throws -> [Transaction] {
        var transactions = [Transaction]()

        let initModuleTransaction = try await initModuleTransaction(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress,
            fee: fee.initFee
        )

        transactions.append(initModuleTransaction)

        if let approveFee = fee.enterFee.approveFee {
            let requestPermissionsTransaction = try await requestPermissionTransaction(
                tokenContractAddress: tokenContractAddress,
                yieldContractAddress: yieldContractAddress,
                fee: approveFee
            )

            transactions.append(requestPermissionsTransaction)
        }

        let enterResult = try await enterTransaction(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress,
            fee: fee.enterFee.enterFee
        )

        transactions.append(enterResult)

        return transactions
    }

    // MARK: - Reactivate

    func reactivateTransactions(
        tokenContractAddress: String,
        yieldContractAddress: String,
        fee: ReactivateEnterFee
    ) async throws -> [Transaction] {
        var transactions = [Transaction]()

        let reactivateTokenTransaction = try await reactivateTokenTransaction(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress,
            fee: fee.reactivateFee
        )

        transactions.append(reactivateTokenTransaction)

        if let approveFee = fee.enterFee.approveFee {
            let requestPermissionsTransaction = try await requestPermissionTransaction(
                tokenContractAddress: tokenContractAddress,
                yieldContractAddress: yieldContractAddress,
                fee: approveFee
            )

            transactions.append(requestPermissionsTransaction)
        }

        let enterResult = try await enterTransaction(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress,
            fee: fee.enterFee.enterFee
        )

        transactions.append(enterResult)

        return transactions
    }

    func enterTransactions(
        tokenContractAddress: String,
        yieldContractAddress: String,
        fee: EnterFee
    ) async throws -> [Transaction] {
        var transactions = [Transaction]()

        if let approveFee = fee.approveFee {
            let requestPermissionsTransaction = try await requestPermissionTransaction(
                tokenContractAddress: tokenContractAddress,
                yieldContractAddress: yieldContractAddress,
                fee: approveFee
            )

            transactions.append(requestPermissionsTransaction)
        }

        let enterResult = try await enterTransaction(
            tokenContractAddress: tokenContractAddress,
            yieldContractAddress: yieldContractAddress,
            fee: fee.enterFee
        )

        transactions.append(enterResult)

        return transactions
    }

    // MARK: - Exit

    func exitTransactions(
        tokenContractAddress: String,
        yieldContractAddress: String,
        fee: ExitFee
    ) async throws -> [Transaction] {
        let method = WithdrawAndDeactivateMethod(tokenContractAddress: tokenContractAddress)

        return try await [transaction(contractAddress: yieldContractAddress, txData: method.data, fee: fee.fee)]
    }
}

// MARK: - Private calls

private extension YieldTransactionProvider {
    private func requestPermissionTransaction(
        tokenContractAddress: String,
        yieldContractAddress: String,
        fee: Fee
    ) async throws -> Transaction {
        let data = try transactionBuilder.buildForApprove(
            spender: yieldContractAddress,
            amount: .greatestFiniteMagnitude
        )

        return try await transaction(contractAddress: tokenContractAddress, txData: data, fee: fee)
    }

    private func deployTransaction(
        walletAddress: String,
        tokenContractAddress: String,
        fee: Fee
    ) async throws -> Transaction {
        let deployAction = DeployYieldModuleMethod(
            walletAddress: walletAddress,
            tokenContractAddress: tokenContractAddress,
            maxNetworkFee: maxNetworkFee
        )

        return try await transaction(
            contractAddress: yieldSupplyContractAddresses.factoryContractAddress,
            txData: deployAction.data,
            fee: fee,
        )
    }

    func initModuleTransaction(
        tokenContractAddress: String,
        yieldContractAddress: String,
        fee: Fee
    ) async throws -> Transaction {
        let smartContract = InitYieldTokenMethod(
            tokenContractAddress: tokenContractAddress,
            maxNetworkFee: maxNetworkFee
        )

        return try await transaction(contractAddress: yieldContractAddress, txData: smartContract.data, fee: fee)
    }

    func reactivateTokenTransaction(
        tokenContractAddress: String,
        yieldContractAddress: String,
        fee: Fee
    ) async throws -> Transaction {
        let smartContract = ReactivateTokenMethod(
            tokenContractAddress: tokenContractAddress,
            maxNetworkFee: maxNetworkFee
        )

        return try await transaction(contractAddress: yieldContractAddress, txData: smartContract.data, fee: fee)
    }

    private func enterTransaction(
        tokenContractAddress: String,
        yieldContractAddress: String,
        fee: Fee
    ) async throws -> Transaction {
        let enterAction = EnterProtocolMethod(
            tokenContractAddress: tokenContractAddress
        )

        return try await transaction(contractAddress: yieldContractAddress, txData: enterAction.data, fee: fee)
    }

    private func transaction(contractAddress: String, txData: Data, fee: Fee) async throws -> Transaction {
        try await transactionCreator.createTransaction(
            amount: Amount(with: blockchain, type: .coin, value: .zero),
            fee: fee,
            destinationAddress: contractAddress,
            contractAddress: contractAddress,
            params: EthereumTransactionParams(data: txData)
        )
    }
}
