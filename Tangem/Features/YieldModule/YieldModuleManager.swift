//
//  YieldModuleManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt
import Combine

public protocol YieldModuleManager {
    func getAPY(contractAddress: String) async throws -> Decimal
    func getYieldModuleState(contractAddress: String) async throws -> YieldModuleState

    func enterFee(contractAddress: String) async throws -> YieldTransactionFee
    func enter(contractAddress: String, fee: YieldTransactionFee) async throws -> [String]

    func exitFee(yieldModule: String, contractAddress: String) async throws -> YieldTransactionFee
    func exit(yieldModule: String, contractAddress: String, fee: YieldTransactionFee) async throws -> [String]
}

final class CommonYieldModuleManager {
    private let walletAddress: String
    private let tokenItem: TokenItem
    private let yieldTokenService: YieldTokenService
    private let tokenBalanceProvider: TokenBalanceProvider
    private let transactionDispatcher: TransactionDispatcher

    private let transactionProvider: YieldTransactionProvider
    private let transactionFeeProvider: YieldTransactionFeeProvider

    init?(
        walletAddress: String,
        tokenItem: TokenItem,
        yieldTokenService: YieldTokenService,
        tokenBalanceProvider: TokenBalanceProvider,
        ethereumNetworkProvider: EthereumNetworkProvider,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder,
        transactionCreator: TransactionCreator,
        transactionDispatcher: TransactionDispatcher
    ) {
        guard let token = tokenItem.token else {
            return nil
        }
        self.walletAddress = walletAddress
        self.tokenItem = tokenItem
        self.yieldTokenService = yieldTokenService
        self.tokenBalanceProvider = tokenBalanceProvider
        self.transactionDispatcher = transactionDispatcher

        transactionProvider = YieldTransactionProvider(
            token: token,
            blockchain: tokenItem.blockchain,
            transactionCreator: transactionCreator,
            transactionBuilder: ethereumTransactionDataBuilder
        )

        let allowanceChecker = AllowanceChecker(
            blockchain: tokenItem.blockchain,
            amountType: tokenItem.amountType,
            walletAddress: walletAddress,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionDataBuilder: ethereumTransactionDataBuilder
        )

        transactionFeeProvider = YieldTransactionFeeProvider(
            blockchain: tokenItem.blockchain,
            ethereumNetworkProvider: ethereumNetworkProvider,
            allowanceChecker: allowanceChecker,
        )

        bind()
    }

    func bind() {}
}

extension CommonYieldModuleManager: YieldModuleManager {
    func getAPY(contractAddress: String) async throws -> Decimal {
        try await yieldTokenService.getAPY(for: contractAddress)
    }

    func getYieldModuleState(contractAddress: String) async throws -> YieldModuleState {
        try await yieldTokenService.getYieldModuleState(for: walletAddress, contractAddress: contractAddress)
    }

    func enterFee(contractAddress: String) async throws -> YieldTransactionFee {
        let yieldTokenState = try await yieldTokenService.getYieldModuleState(
            for: walletAddress,
            contractAddress: contractAddress
        )

        switch yieldTokenState {
        case .notDeployed:
            return try await transactionFeeProvider.deployFee(address: walletAddress, contractAddress: contractAddress)
        case .deployed(let deployed):
            guard let balanceValue = tokenBalanceProvider.balanceType.value else {
                throw YieldServiceError.balanceNotFound
            }

            let balance = balanceValue * tokenItem.blockchain.decimalValue

            switch deployed.initializationState {
            case .notInitialized:
                return try await transactionFeeProvider.initializeFee(
                    address: walletAddress,
                    yieldModule: deployed.yieldModule,
                    balance: balance
                )
            case .initialized(.notActive):
                return try await transactionFeeProvider.reactivateFee(
                    address: walletAddress,
                    yieldModule: deployed.yieldModule,
                    balance: balance
                )
            case .initialized(.active):
                throw YieldServiceError.yieldIsAlreadyActive
            }
        }
    }

    func enter(contractAddress: String, fee: any YieldTransactionFee) async throws -> [String] {
        let yieldTokenState = try await yieldTokenService.getYieldModuleState(
            for: walletAddress,
            contractAddress: contractAddress
        )

        var transactions = [Transaction]()

        switch (yieldTokenState, fee) {
        case (.notDeployed, let deployEnterFee as DeployEnterFee):
            let yieldModule = try await yieldTokenService.calculateYieldAddress(for: walletAddress)

            guard let balance = tokenBalanceProvider.balanceType.value,
                  let balanceBigUInt = BigUInt(decimal: balance * tokenItem.decimalValue) else {
                throw YieldServiceError.balanceNotFound
            }

            let deployTransactions = try await transactionProvider.deployTransactions(
                yieldModule: yieldModule,
                balance: balanceBigUInt,
                address: walletAddress,
                contractAddress: contractAddress,
                fee: deployEnterFee
            )

            transactions.append(contentsOf: deployTransactions)
        case (.deployed(let deployed), let fee):
            switch (deployed.initializationState, fee) {
            case (.notInitialized, let initFee as InitEnterFee):
                let initTransactions = try await transactionProvider.initTransactions(
                    contractAddress: contractAddress,
                    yieldModule: deployed.yieldModule,
                    fee: initFee
                )

                transactions.append(contentsOf: initTransactions)
            case (.initialized(.notActive), let reactivateFee as ReactivateEnterFee):
                let reactivateTransactions = try await transactionProvider.reactivateTransactions(
                    contractAddress: contractAddress,
                    yieldModule: deployed.yieldModule,
                    fee: reactivateFee
                )

                transactions.append(contentsOf: reactivateTransactions)
            case (.initialized, _):
                throw YieldServiceError.yieldIsAlreadyActive
            default:
                throw YieldServiceError.inconsistentState
            }
        default: throw YieldServiceError.inconsistentState
        }

        return try await transactionDispatcher
            .send(transactions: transactions.map(SendTransactionType.transfer))
            .map(\.hash)
    }

    func exitFee(yieldModule: String, contractAddress: String) async throws -> any YieldTransactionFee {
        try await transactionFeeProvider.exitFee(yieldModule: yieldModule, contractAddress: contractAddress)
    }

    func exit(yieldModule: String, contractAddress: String, fee: YieldTransactionFee) async throws -> [String] {
        let yieldTokenState = try await yieldTokenService.getYieldModuleState(
            for: walletAddress,
            contractAddress: contractAddress
        )

        guard case .deployed(let deployedState) = yieldTokenState,
              case .initialized(let activeState) = deployedState.initializationState,
              case .active = activeState, let exitFee = fee as? ExitFee else {
            throw YieldServiceError.yieldIsNotActive
        }

        let transactions = try await transactionProvider.exitTransactions(
            contractAddress: contractAddress,
            yieldModule: yieldModule,
            fee: exitFee
        )

        return try await transactionDispatcher
            .send(transactions: transactions.map(SendTransactionType.transfer))
            .map(\.hash)
    }
}
