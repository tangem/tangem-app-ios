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

    init(
        token: Token,
        blockchain: Blockchain,
        transactionCreator: TransactionCreator,
        transactionBuilder: EthereumTransactionDataBuilder,
        yieldSupplyContractAddresses: YieldSupplyContractAddresses
    ) {
        self.token = token
        self.blockchain = blockchain
        self.transactionCreator = transactionCreator
        self.transactionBuilder = transactionBuilder
        self.yieldSupplyContractAddresses = yieldSupplyContractAddresses
    }

    // MARK: - Deploy

    func deployTransactions(
        yieldModule: String,
        balance: BigUInt,
        address: String,
        contractAddress: String,
        fee: DeployEnterFee
    ) async throws -> [Transaction] {
        let deployTransaction = try await deployTransaction(
            address: address,
            contractAddress: yieldSupplyContractAddresses.factoryContractAddress,
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

    // MARK: - Init

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

    // MARK: - Reactivate

    func reactivateTransactions(
        contractAddress: String,
        yieldModule: String,
        fee: ReactivateEnterFee
    ) async throws -> [Transaction] {
        var transactions = [Transaction]()

        let reactivateTokenTransaction = try await reactivateTokenTransaction(
            contractAddress: contractAddress,
            yieldModule: yieldModule,
            fee: fee.reactivateFee
        )

        transactions.append(reactivateTokenTransaction)

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

    func enterTransactions(
        contractAddress: String,
        yieldModule: String,
        fee: EnterFee
    ) async throws -> [Transaction] {
        var transactions = [Transaction]()

        if let approveFee = fee.approveFee {
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
            fee: fee.enterFee
        )

        transactions.append(enterResult)

        return transactions
    }

    // MARK: - Exit

    func exitTransactions(
        contractAddress: String,
        yieldModule: String,
        fee: ExitFee
    ) async throws -> [Transaction] {
        let method = WithdrawAndDeactivateMethod(yieldModuleAddress: contractAddress)

        return try await [transaction(contractAddress: yieldModule, txData: method.data, fee: fee.fee)]
    }
}

// MARK: - Private calls

private extension YieldTransactionProvider {
    private func requestPermissionTransaction(
        contractAddress: String,
        yieldModule: String,
        fee: Fee
    ) async throws -> Transaction {
        let data = try transactionBuilder.buildForApprove(spender: yieldModule, amount: .greatestFiniteMagnitude)

        return try await transaction(contractAddress: contractAddress, txData: data, fee: fee)
    }

    private func deployTransaction(address: String, contractAddress: String, fee: Fee) async throws -> Transaction {
        let deployAction = DeployYieldModuleMethod(
            sourceAddress: address,
            tokenAddress: contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * blockchain.decimalValue)!
        )

        return try await transaction(
            contractAddress: yieldSupplyContractAddresses.factoryContractAddress,
            txData: deployAction.data,
            fee: fee,
        )
    }

    func initModuleTransaction(contractAddress: String, yieldModule: String, fee: Fee) async throws -> Transaction {
        let smartContract = InitYieldTokenMethod(
            yieldModuleAddress: contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * blockchain.decimalValue)!
        )

        return try await transaction(contractAddress: yieldModule, txData: smartContract.data, fee: fee)
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

        return try await transaction(contractAddress: yieldModule, txData: smartContract.data, fee: fee)
    }

    private func initTokenTransaction(
        contractAddress: String,
        yieldModule: String,
        fee: Fee
    ) async throws -> Transaction {
        let smartContract = InitYieldTokenMethod(
            yieldModuleAddress: contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * blockchain.decimalValue)!
        )

        return try await transaction(contractAddress: yieldModule, txData: smartContract.data, fee: fee)
    }

    private func enterTransaction(
        contractAddress: String,
        yieldModule: String,
        fee: Fee
    ) async throws -> Transaction {
        let enterAction = EnterProtocolMethod(
            yieldModuleAddress: contractAddress
        )

        return try await transaction(contractAddress: yieldModule, txData: enterAction.data, fee: fee)
    }

    private func transaction(contractAddress: String, txData: Data, fee: Fee) async throws -> Transaction {
        try await transactionCreator.createTransaction(
            amount: Amount(with: fee.amount, value: .zero),
            fee: fee,
            destinationAddress: contractAddress,
            contractAddress: contractAddress,
            params: EthereumTransactionParams(data: txData)
        )
    }
}
