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
    private let yieldSupplyContractAddresses: YieldSupplyContractAddresses
    private let validatesFee: Bool

    init(
        token: Token,
        blockchain: Blockchain,
        transactionCreator: TransactionCreator,
        yieldSupplyContractAddresses: YieldSupplyContractAddresses,
        validatesFee: Bool = true
    ) {
        self.token = token
        self.blockchain = blockchain
        self.transactionCreator = transactionCreator
        self.yieldSupplyContractAddresses = yieldSupplyContractAddresses
        self.validatesFee = validatesFee
    }

    // MARK: - Deploy

    func deployTransactions(
        walletAddress: String,
        tokenContractAddress: String,
        yieldContractAddress: String,
        maxNetworkFee: BigUInt,
        fee: DeployEnterFee,
        enterAmount: BigUInt? = nil
    ) async throws -> [Transaction] {
        var transactions = [Transaction]()

        transactions.append(
            try await deployTransaction(
                walletAddress: walletAddress,
                tokenContractAddress: tokenContractAddress,
                maxNetworkFee: maxNetworkFee,
                fee: fee.deployFee
            )
        )

        transactions.append(
            try await approveTransaction(
                tokenContractAddress: tokenContractAddress,
                yieldContractAddress: yieldContractAddress,
                fee: fee.approveFee,
            )
        )

        if let enterFee = fee.enterFee {
            transactions.append(
                try await enterTransaction(
                    tokenContractAddress: tokenContractAddress,
                    yieldContractAddress: yieldContractAddress,
                    amount: enterAmount,
                    fee: enterFee
                )
            )
        }

        return transactions
    }

    // MARK: - Init

    func initTransactions(
        tokenContractAddress: String,
        yieldContractAddress: String,
        maxNetworkFee: BigUInt,
        fee: InitEnterFee,
        enterAmount: BigUInt? = nil
    ) async throws -> [Transaction] {
        var transactions = [Transaction]()

        transactions.append(
            try await initModuleTransaction(
                tokenContractAddress: tokenContractAddress,
                yieldContractAddress: yieldContractAddress,
                maxNetworkFee: maxNetworkFee,
                newImplementationAddress: fee.newImplementationAddress,
                fee: fee.initFee
            )
        )

        transactions.append(
            try await approveTransaction(
                tokenContractAddress: tokenContractAddress,
                yieldContractAddress: yieldContractAddress,
                fee: fee.approveFee
            )
        )

        if let enterFee = fee.enterFee {
            transactions.append(
                try await enterTransaction(
                    tokenContractAddress: tokenContractAddress,
                    yieldContractAddress: yieldContractAddress,
                    amount: enterAmount,
                    fee: enterFee
                )
            )
        }

        return transactions
    }

    // MARK: - Reactivate

    func reactivateTransactions(
        tokenContractAddress: String,
        yieldContractAddress: String,
        maxNetworkFee: BigUInt,
        fee: ReactivateEnterFee,
        enterAmount: BigUInt? = nil
    ) async throws -> [Transaction] {
        var transactions = [Transaction]()

        transactions.append(
            try await reactivateTokenTransaction(
                tokenContractAddress: tokenContractAddress,
                yieldContractAddress: yieldContractAddress,
                maxNetworkFee: maxNetworkFee,
                newImplementationAddress: fee.newImplementationAddress,
                fee: fee.reactivateFee
            )
        )

        if let approveFee = fee.approveFee {
            transactions.append(
                try await approveTransaction(
                    tokenContractAddress: tokenContractAddress,
                    yieldContractAddress: yieldContractAddress,
                    fee: approveFee
                )
            )
        }

        if let enterFee = fee.enterFee {
            transactions.append(
                try await enterTransaction(
                    tokenContractAddress: tokenContractAddress,
                    yieldContractAddress: yieldContractAddress,
                    amount: enterAmount,
                    fee: enterFee
                )
            )
        }

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

    // MARK: - Claim

    /// The exact backend-provided `to`/`data` pair — the calldata is opaque and submitted as is, with zero value.
    func claimTransaction(to: String, data: Data, fee: Fee) async throws -> Transaction {
        try await transaction(contractAddress: to, txData: data, fee: fee)
    }

    // MARK: - Approve

    func approveTransaction(
        tokenContractAddress: String,
        yieldContractAddress: String,
        fee: Fee
    ) async throws -> Transaction {
        let method = ApproveERC20TokenMethod(
            spender: yieldContractAddress,
            amount: .maxUInt256
        )

        return try await transaction(contractAddress: tokenContractAddress, txData: method.data, fee: fee)
    }
}

// MARK: - Private calls

private extension YieldTransactionProvider {
    private func deployTransaction(
        walletAddress: String,
        tokenContractAddress: String,
        maxNetworkFee: BigUInt,
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
        maxNetworkFee: BigUInt,
        newImplementationAddress: String?,
        fee: Fee
    ) async throws -> Transaction {
        let smartContract = InitYieldTokenMethod(
            tokenContractAddress: tokenContractAddress,
            maxNetworkFee: maxNetworkFee
        )
        let txData = UpgradeToAndCallMethod.wrapIfNeeded(smartContract.data, newImplementation: newImplementationAddress)

        return try await transaction(contractAddress: yieldContractAddress, txData: txData, fee: fee)
    }

    func reactivateTokenTransaction(
        tokenContractAddress: String,
        yieldContractAddress: String,
        maxNetworkFee: BigUInt,
        newImplementationAddress: String?,
        fee: Fee
    ) async throws -> Transaction {
        let smartContract = ReactivateTokenMethod(
            tokenContractAddress: tokenContractAddress,
            maxNetworkFee: maxNetworkFee
        )
        let txData = UpgradeToAndCallMethod.wrapIfNeeded(smartContract.data, newImplementation: newImplementationAddress)

        return try await transaction(contractAddress: yieldContractAddress, txData: txData, fee: fee)
    }

    private func enterTransaction(
        tokenContractAddress: String,
        yieldContractAddress: String,
        amount: BigUInt?,
        fee: Fee
    ) async throws -> Transaction {
        let enterData = if let amount {
            EnterProtocolWithAmountMethod(tokenContractAddress: tokenContractAddress, amount: amount).data
        } else {
            EnterProtocolMethod(tokenContractAddress: tokenContractAddress).data
        }

        return try await transaction(contractAddress: yieldContractAddress, txData: enterData, fee: fee)
    }

    private func transaction(contractAddress: String, txData: Data, fee: Fee) async throws -> Transaction {
        let amount = Amount(with: blockchain, type: .coin, value: .zero)
        let params = EthereumTransactionParams(data: txData)

        guard validatesFee else {
            let wallet = transactionCreator.wallet

            return Transaction(
                amount: amount,
                fee: fee,
                sourceAddress: wallet.address,
                destinationAddress: contractAddress,
                changeAddress: wallet.changeAddress.value,
                contractAddress: contractAddress,
                params: params
            )
        }

        return try await transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: contractAddress,
            contractAddress: contractAddress,
            params: params
        )
    }
}
