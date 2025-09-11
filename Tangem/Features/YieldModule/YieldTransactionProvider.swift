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

    init(
        token: Token,
        blockchain: Blockchain,
        transactionCreator: TransactionCreator,
        transactionBuilder: EthereumTransactionDataBuilder
    ) {
        self.token = token
        self.blockchain = blockchain
        self.transactionCreator = transactionCreator
        self.transactionBuilder = transactionBuilder
    }

    func deployTransactions(
        yieldModule: String,
        balance: BigUInt,
        address: String,
        contractAddress: String,
        fee: DeployEnterFee
    ) async throws -> [Transaction] {
        let deployTransaction = try await deployTransaction(
            address: address,
            contractAddress: YieldConstants.yieldModuleFactoryContractAddress,
            fee: fee.deployFee
        )

        let approveTransaction = try await requestPermissionTransaction(
            contractAddress: contractAddress,
            yieldModule: yieldModule,
            fee: fee.approveFee,
        )

        let enterResult = try await enterTransaction(
            contractAddress: contractAddress,
            yieldModule: yieldModule,
            fee: fee.enterFee
        )

        return [deployTransaction, approveTransaction, enterResult]
    }

    func initTransactions(
        contractAddress: String,
        yieldModule: String,
        fee: InitEnterFee
    ) async throws -> [Transaction] {
        var transactions = [Transaction]()

        let initModuleTransaction = try await initModuleTransaction(
            contractAddress: contractAddress,
            yieldModule: yieldModule,
            fee: fee.initFee
        )

        transactions.append(initModuleTransaction)

        if let approveFee = fee.enterFee.approveFee {
            let requestPermissionsTransaction = try await requestPermissionTransaction(
                contractAddress: contractAddress,
                yieldModule: yieldModule,
                fee: approveFee
            )

            transactions.append(requestPermissionsTransaction)
        }

        let enterResult = try await enterTransaction(
            contractAddress: contractAddress,
            yieldModule: yieldModule,
            fee: fee.enterFee.enterFee
        )

        transactions.append(enterResult)

        return transactions
    }

    func reactivateTransactions(
        contractAddress: String,
        yieldModule: String,
        fee: ReactivateEnterFee
    ) async throws -> [Transaction] {
        var transactions = [Transaction]()

        let initModuleTransaction = try await reactivateTokenTransaction(
            contractAddress: contractAddress,
            yieldModule: yieldModule,
            fee: fee.reactivateFee
        )

        transactions.append(initModuleTransaction)

        if let approveFee = fee.enterFee.approveFee {
            let requestPermissionsTransaction = try await requestPermissionTransaction(
                contractAddress: contractAddress,
                yieldModule: yieldModule,
                fee: approveFee
            )

            transactions.append(requestPermissionsTransaction)
        }

        let enterResult = try await enterTransaction(
            contractAddress: contractAddress,
            yieldModule: yieldModule,
            fee: fee.enterFee.enterFee
        )

        transactions.append(enterResult)

        return transactions
    }

    func exitTransactions(
        contractAddress: String,
        yieldModule: String,
        fee: ExitFee
    ) async throws -> [Transaction] {
        let method = WithdrawAndDeactivateMethod(yieldTokenAddress: contractAddress)

        return try await [transaction(yieldModule: yieldModule, txData: method.data, fee: fee.fee)]
    }
}

private extension YieldTransactionProvider {
    private func requestPermissionTransaction(
        contractAddress: String,
        yieldModule: String,
        fee: Fee
    ) async throws -> Transaction {
        let data = try transactionBuilder.buildForApprove(spender: contractAddress, amount: .greatestFiniteMagnitude)
        return try await transaction(yieldModule: yieldModule, txData: data, fee: fee)
    }

    private func deployTransaction(address: String, contractAddress: String, fee: Fee) async throws -> Transaction {
        let deployAction = DeployYieldModuleMethod(
            sourceAddress: address,
            tokenAddress: contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * blockchain.decimalValue)!
        )

        return try await transaction(
            yieldModule: YieldConstants.yieldModuleFactoryContractAddress,
            txData: deployAction.data,
            fee: fee,
        )
    }

    func initModuleTransaction(contractAddress: String, yieldModule: String, fee: Fee) async throws -> Transaction {
        let smartContract = InitYieldTokenMethod(
            yieldTokenAddress: contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * blockchain.decimalValue)!
        )

        return try await transaction(yieldModule: yieldModule, txData: smartContract.data, fee: fee)
    }

    func reactivateTokenTransaction(
        contractAddress: String,
        yieldModule: String,
        fee: Fee
    ) async throws -> Transaction {
        let smartContract = ReactivateTokenMethod(
            contractAddress: contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * blockchain.decimalValue)!
        )

        return try await transaction(yieldModule: yieldModule, txData: smartContract.data, fee: fee)
    }

    private func initTokenTransaction(
        contractAddress: String,
        yieldModule: String,
        fee: Fee
    ) async throws -> Transaction {
        let smartContract = InitYieldTokenMethod(
            yieldTokenAddress: contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * blockchain.decimalValue)!
        )

        return try await transaction(yieldModule: yieldModule, txData: smartContract.data, fee: fee)
    }

    private func enterTransaction(
        contractAddress: String,
        yieldModule: String,
        fee: Fee
    ) async throws -> Transaction {
        let enterAction = EnterProtocolMethod(
            yieldTokenAddress: contractAddress
        )

        return try await transaction(yieldModule: yieldModule, txData: enterAction.data, fee: fee)
    }

    private func transaction(yieldModule: String, txData: Data, fee: Fee) async throws -> Transaction {
        try await transactionCreator.createTransaction(
            amount: Amount(with: token, value: .zero),
            fee: fee,
            destinationAddress: yieldModule,
            contractAddress: yieldModule,
            params: EthereumTransactionParams(data: txData)
        )
    }
}
