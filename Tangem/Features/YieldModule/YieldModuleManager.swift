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
    func isYieldModuleActive(for address: String, contractAddress: String) async throws -> Bool

    func enterFee(for address: String, contractAddress: String) async throws -> YieldTransactionFee
    func enter(for address: String, contractAddress: String, fee: YieldTransactionFee) async throws -> [String]

    func exitFee(for address: String, contractAddress: String) async throws -> YieldTransactionFee
    func exit(for address: String, contractAddress: String, fee: YieldTransactionFee) async throws -> String
}

final class CommonYieldModuleManager {
    private let address: String
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let yieldTokenService: YieldTokenService
    private let tokenBalanceProvider: TokenBalanceProvider
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let ethereumTransactionDataBuilder: EthereumTransactionDataBuilder
    private let transactionCreator: TransactionCreator
    private let transactionDispatcher: TransactionDispatcher

    init(
        address: String,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        yieldTokenService: YieldTokenService,
        tokenBalanceProvider: TokenBalanceProvider,
        ethereumNetworkProvider: EthereumNetworkProvider,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder,
        transactionCreator: TransactionCreator,
        transactionDispatcher: TransactionDispatcher
    ) {
        self.address = address
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.yieldTokenService = yieldTokenService
        self.tokenBalanceProvider = tokenBalanceProvider
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.ethereumTransactionDataBuilder = ethereumTransactionDataBuilder
        self.transactionCreator = transactionCreator
        self.transactionDispatcher = transactionDispatcher

        bind()
    }

    func bind() {}
}

extension CommonYieldModuleManager: YieldModuleManager {
    func isYieldModuleActive(for address: String, contractAddress: String) async throws -> Bool {
        try await yieldTokenService.getYieldTokenState(for: address, contractAddress: contractAddress).isActive
    }

    func enterFee(for address: String, contractAddress: String) async throws -> YieldTransactionFee {
        let yieldTokenState = try await yieldTokenService.getYieldTokenState(
            for: address,
            contractAddress: contractAddress
        )

        switch yieldTokenState {
        case .notDeployed:
            let yieldModuleAddressMethod = DeployYieldModuleMethod(
                sourceAddress: address,
                tokenAddress: contractAddress,
                maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee)!
            )
            let yieldModuleAddressMethodFee = try await estimateFee(
                contractAddress: YieldConstants.yieldModuleFactoryContractAddress,
                transactionData: yieldModuleAddressMethod.data
            )

            return DeployEnterFee(deployFee: yieldModuleAddressMethodFee)
        case .deployed(let deployed):
            switch deployed.initializationState {
            case .notInitialized:
                let initModuleMethod = InitYieldTokenMethod(
                    yieldTokenAddress: contractAddress,
                    maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee)!
                )

                async let initFee = estimateFee(
                    contractAddress: deployed.yieldToken,
                    transactionData: initModuleMethod.data
                )

                return try await InitEnterFee(initFee: initFee)
            case .initialized(.notActive):
                let reactivateModuleMethod = ReactivateTokenMethod(
                    contractAddress: contractAddress
                )
                let enterMethod = EnterProtocolMethod(yieldTokenAddress: deployed.yieldToken)

                async let reactivateFee = estimateFee(
                    contractAddress: deployed.yieldToken,
                    transactionData: reactivateModuleMethod.data
                )
                async let approveData = try await approveData(address: address, contractAddress: deployed.yieldToken)
                async let enterFee = try await estimateFee(
                    contractAddress: deployed.yieldToken,
                    transactionData: enterMethod.data
                )

                return try await ReactivateEnterFee(
                    reactivateFee: reactivateFee,
                    enterFee: .init(enterFee: enterFee, approveFee: approveData?.fee)
                )
            case .initialized(.active):
//                throw YieldServiceError.yieldIsAlreadyActive
                let enterMethod = EnterProtocolMethod(yieldTokenAddress: contractAddress)

                let approveData = try await approveData(address: address, contractAddress: deployed.yieldToken)

                async let enterFee = try await estimateFee(
                    contractAddress: deployed.yieldToken,
                    transactionData: enterMethod.data
                )

                return try await EnterFee(enterFee: enterFee, approveFee: approveData?.fee)
            }
        }
    }

    func enter(for address: String, contractAddress: String, fee: any YieldTransactionFee) async throws -> [String] {
        let yieldTokenState = try await yieldTokenService.getYieldTokenState(
            for: address,
            contractAddress: contractAddress
        )

        var transactions = [Transaction]()

        switch (yieldTokenState, fee) {
        case (.notDeployed, let deployEnterFee as DeployEnterFee):
            let yieldModule = try await yieldTokenService.calculateYieldAddress(for: address)

            guard let balance = tokenBalanceProvider.balanceType.value,
                  let balanceBigUInt = BigUInt(decimal: balance * tokenItem.decimalValue) else {
                throw YieldServiceError.balanceNotFound
            }

            let deployResult = try await deploy(
                address: address,
                contractAddress: YieldConstants.yieldModuleFactoryContractAddress,
                fee: deployEnterFee.deployFee
            )

            transactions.append(deployResult)

            let approveMethod = ApproveERC20TokenMethod(
                spender: yieldModule,
                amount: balanceBigUInt
            )

            let approveResult = try await requestPermissions(
                approveData: ApproveTransactionData(
                    txData: approveMethod.data,
                    spender: yieldModule,
                    toContractAddress: contractAddress,
                    fee: deployEnterFee.enterFee.approveFee!
                )
            )

            transactions.append(approveResult)

            let enterResult = try await enter(
                yieldToken: yieldModule,
                contractAddress: contractAddress,
                fee: deployEnterFee.enterFee.enterFee
            )

            transactions.append(enterResult)

        case (.deployed(let deployed), let fee):
            switch (deployed.initializationState, fee) {
            case (.notInitialized, let initFee as InitEnterFee):
                let initFeeResult = try await initToken(
                    contractAddress: contractAddress,
                    yieldToken: deployed.yieldToken,
                    fee: initFee.initFee
                )

                transactions.append(initFeeResult)

                let approveData = try await approveData(address: address, contractAddress: deployed.yieldToken)

                if let approveData {
                    let requestPermissions = try await requestPermissions(
                        approveData: approveData
                    )

                    transactions.append(requestPermissions)
                }

                let enterResult = try await enter(
                    yieldToken: deployed.yieldToken,
                    contractAddress: contractAddress,
                    fee: initFee.enterFee.enterFee
                )

                transactions.append(enterResult)
            case (.initialized(.notActive), let reactivateFee as ReactivateEnterFee):
                let initFeeResult = try await reactivateToken(
                    contractAddress: contractAddress,
                    yieldToken: deployed.yieldToken,
                    fee: reactivateFee.reactivateFee
                )

                transactions.append(initFeeResult)

                let approveData = try await approveData(address: address, contractAddress: deployed.yieldToken)

                if let approveData {
                    let requestPermissions = try await requestPermissions(
                        approveData: approveData
                    )

                    transactions.append(requestPermissions)
                }

                let enterResult = try await enter(
                    yieldToken: deployed.yieldToken,
                    contractAddress: contractAddress,
                    fee: reactivateFee.enterFee.enterFee
                )

                transactions.append(enterResult)
            case (.initialized, let enterFee as EnterFee):
//                throw YieldServiceError.yieldIsAlreadyActive

                let approveData = try await approveData(address: address, contractAddress: deployed.yieldToken)

                if let approveData {
                    let requestPermissions = try await requestPermissions(
                        approveData: approveData
                    )

                    transactions.append(requestPermissions)
                }

//                do {
                let enterResult = try await enter(
                    yieldToken: deployed.yieldToken,
                    contractAddress: contractAddress,
                    fee: enterFee.enterFee
                )

                transactions.append(enterResult)
//                } catch {
//                    return [""]
//                }
            default:
                throw YieldServiceError.inconsistentState
            }

        default: throw YieldServiceError.inconsistentState
        }

        return try await transactionDispatcher.send(
            transactions: transactions.map(SendTransactionType.transfer)
        ).map(\.hash)
    }

    func exitFee(for address: String, contractAddress: String) async throws -> any YieldTransactionFee {
        let result = try await exitMethod(for: address, contractAddress: contractAddress)

        let enterFee = try await estimateFee(
            contractAddress: result.1,
            transactionData: result.0.data
        )

        return EnterFee(enterFee: enterFee, approveFee: nil)
    }

    func exit(for address: String, contractAddress: String, fee: YieldTransactionFee) async throws -> String {
        let result = try await exitMethod(for: address, contractAddress: contractAddress)

        guard let fee = fee as? EnterFee else {
            throw YieldServiceError.inconsistentState
        }

        let exitResult = try await exit(yieldToken: result.1, contractAddress: contractAddress, fee: fee.enterFee)
        return try await transactionDispatcher.send(
            transaction: .transfer(exitResult)
        ).hash
    }
}

private extension CommonYieldModuleManager {
    private func exitMethod(
        for address: String,
        contractAddress: String
    ) async throws -> (YieldSmartContractMethod, String) {
        let yieldTokenState = try await yieldTokenService.getYieldTokenState(
            for: address,
            contractAddress: contractAddress
        )

        if case .deployed(let deployedState) = yieldTokenState,
           case .initialized(let activeState) = deployedState.initializationState,
           case .active = activeState {
            return (WithdrawAndDeactivateMethod(yieldTokenAddress: contractAddress), deployedState.yieldToken)
        } else {
            throw YieldServiceError.yieldIsNotActive
        }
    }

    func requestPermissions(
        approveData: ApproveTransactionData
    ) async throws -> Transaction {
        try await transactionCreator.buildTransaction(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            amount: 0,
            fee: approveData.fee,
            destination: .contractCall(contract: approveData.toContractAddress, data: approveData.txData)
        )
    }

    private func initToken(contractAddress: String, yieldToken: String, fee: Fee) async throws -> Transaction {
        let smartContract = InitYieldTokenMethod(
            yieldTokenAddress: contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * tokenItem.blockchain.decimalValue)!
        )

        return try await execute(yieldModule: yieldToken, yieldMethod: smartContract, fee: fee)
    }

    private func deploy(address: String, contractAddress: String, fee: Fee) async throws -> Transaction {
        let deployAction = DeployYieldModuleMethod(
            sourceAddress: address,
            tokenAddress: contractAddress,
            maxNetworkFee: BigUInt(decimal: YieldConstants.maxNetworkFee * tokenItem.blockchain.decimalValue)!
        )

        return try await execute(
            yieldModule: YieldConstants.yieldModuleFactoryContractAddress,
            yieldMethod: deployAction,
            fee: fee,
        )
    }

    private func enter(
        yieldToken: String,
        contractAddress: String,
        fee: Fee
    ) async throws -> Transaction {
        let enterAction = EnterProtocolMethod(
            yieldTokenAddress: contractAddress
        )

        return try await execute(yieldModule: yieldToken, yieldMethod: enterAction, fee: fee)
    }

    private func exit(
        yieldToken: String,
        contractAddress: String,
        fee: Fee
    ) async throws -> Transaction {
        let exitAction = WithdrawAndDeactivateMethod(
            yieldTokenAddress: contractAddress
        )

        return try await execute(yieldModule: yieldToken, yieldMethod: exitAction, fee: fee)
    }

    private func reactivateToken(contractAddress: String, yieldToken: String, fee: Fee) async throws -> Transaction {
        let reactivateAction = ReactivateTokenMethod(
            contractAddress: contractAddress
        )

        return try await execute(yieldModule: yieldToken, yieldMethod: reactivateAction, fee: fee)
    }

    private func approveData(address: String, contractAddress: String) async throws -> ApproveTransactionData? {
        let allowanceChecker = AllowanceChecker(
            blockchain: tokenItem.blockchain,
            amountType: tokenItem.amountType,
            walletAddress: address,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionDataBuilder: ethereumTransactionDataBuilder
        )

        guard let balance = tokenBalanceProvider.balanceType.value else {
            throw YieldServiceError.balanceNotFound
        }

        let isPermissionRequired = try await allowanceChecker.isPermissionRequired(
            amount: balance * tokenItem.decimalValue,
            spender: contractAddress
        )

        guard isPermissionRequired else {
            return nil
        }

        return try await allowanceChecker.makeApproveData(
            spender: contractAddress,
            amount: .greatestFiniteMagnitude,
            policy: .unlimited
        )
    }

    private func estimateFee(contractAddress: String, transactionData: Data) async throws -> Fee {
        let amount = Amount(with: tokenItem.blockchain, type: .coin, value: 0)

        let fees = try await ethereumNetworkProvider.getFee(
            destination: contractAddress,
            value: amount.encodedForSend,
            data: transactionData
        ).async()

        guard let fee = fees.first else {
            throw YieldServiceError.feeNotFound
        }

        return fee
    }

    private func execute(yieldModule: String, yieldMethod: YieldSmartContractMethod, fee: Fee) async throws -> Transaction {
        try await transactionCreator.createTransaction(
            amount: Amount(with: tokenItem.token!, value: .zero),
            fee: fee,
            destinationAddress: yieldModule,
            contractAddress: yieldModule,
            params: EthereumTransactionParams(data: yieldMethod.data)
        )
    }
}
