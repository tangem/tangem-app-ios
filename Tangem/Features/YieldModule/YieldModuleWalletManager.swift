//
//  YieldModuleWalletManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt
import Combine
import TangemFoundation

protocol YieldModuleWalletManager {
    var state: YieldModuleWalletManagerState? { get }
    var statePublisher: AnyPublisher<YieldModuleWalletManagerState, Error> { get }

    func updateState() async

    func enterFee() async throws -> YieldTransactionFee
    func enter(fee: YieldTransactionFee) async throws -> [String]

    func exitFee(yieldModule: String) async throws -> YieldTransactionFee
    func exit(yieldModule: String, fee: YieldTransactionFee) async throws -> [String]
}

enum YieldModuleWalletManagerState {
    case notEnabled
    case enabled(LoadingValue<YieldModuleWalletManagerStateInfo>)

    var balance: Amount? {
        if case .enabled(.loaded(let value)) = self {
            return value.smartContractState.balance
        }
        return nil
    }

    var yieldModule: String? {
        if case .enabled(.loaded(let value)) = self {
            return value.smartContractState.yieldModule
        }
        return nil
    }
}

struct YieldModuleWalletManagerStateInfo {
    let apy: Decimal
    let activeState: YieldModuleActiveState
    let smartContractState: YieldModuleSmartContractState
}

final class CommonYieldModuleWalletManager {
    private let walletAddress: String
    private let token: Token
    private let blockchain: Blockchain
    private let yieldSupplyProvider: YieldSupplyProvider
    private let tokenBalanceProvider: TokenBalanceProvider
    private let transactionDispatcher: TransactionDispatcher

    private let allowanceChecker: AllowanceChecker
    private let transactionProvider: YieldTransactionProvider
    private let transactionFeeProvider: YieldTransactionFeeProvider

    private var _state = CurrentValueSubject<YieldModuleWalletManagerState?, Error>(nil)

    init(
        walletAddress: String,
        token: Token,
        blockchain: Blockchain,
        yieldSupplyProvider: YieldSupplyProvider,
        tokenBalanceProvider: TokenBalanceProvider,
        ethereumNetworkProvider: EthereumNetworkProvider,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder,
        transactionCreator: TransactionCreator,
        transactionDispatcher: TransactionDispatcher
    ) {
        self.walletAddress = walletAddress
        self.token = token
        self.blockchain = blockchain
        self.yieldSupplyProvider = yieldSupplyProvider
        self.tokenBalanceProvider = tokenBalanceProvider
        self.transactionDispatcher = transactionDispatcher

        transactionProvider = YieldTransactionProvider(
            token: token,
            blockchain: blockchain,
            transactionCreator: transactionCreator,
            transactionBuilder: ethereumTransactionDataBuilder
        )

        allowanceChecker = AllowanceChecker(
            blockchain: blockchain,
            amountType: .token(value: token),
            walletAddress: walletAddress,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionDataBuilder: ethereumTransactionDataBuilder
        )

        transactionFeeProvider = YieldTransactionFeeProvider(
            blockchain: blockchain,
            ethereumNetworkProvider: ethereumNetworkProvider,
            allowanceChecker: allowanceChecker,
        )

        bind()
    }
}

extension CommonYieldModuleWalletManager: YieldModuleWalletManager {
    var state: YieldModuleWalletManagerState? {
        _state.value
    }

    var statePublisher: AnyPublisher<YieldModuleWalletManagerState, any Error> {
        _state
            .compactMap { $0 }
            .receiveOnMain()
            .eraseToAnyPublisher()
    }

    func updateState() async {
        _state.send(.enabled(.loading))
        async let apy = getAPY()
        async let yieldModuleState = getYieldModuleState()

        do {
            let state = try await YieldModuleWalletManagerStateInfo(
                apy: apy,
                activeState: .active,
                smartContractState: yieldModuleState
            )
            _state.send(.enabled(.loaded(state)))
        } catch {
            _state.send(.enabled(.failedToLoad(error: error)))
        }
    }

    func enterFee() async throws -> YieldTransactionFee {
        let yieldTokenState = try await getYieldModuleState()

        switch yieldTokenState {
        case .notDeployed:
            return try await transactionFeeProvider.deployFee(
                address: walletAddress,
                contractAddress: token.contractAddress
            )
        case .deployed(let deployed):
            guard let balanceValue = tokenBalanceProvider.balanceType.value else {
                throw YieldModuleError.balanceNotFound
            }

            let balance = balanceValue * blockchain.decimalValue

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
                return try await transactionFeeProvider.enterFee(
                    address: walletAddress,
                    yieldModule: deployed.yieldModule,
                    balance: balance
                )
            }
        }
    }

    func enter(fee: any YieldTransactionFee) async throws -> [String] {
        let yieldTokenState = try await getYieldModuleState()

        var transactions = [Transaction]()

        switch (yieldTokenState, fee) {
        case (.notDeployed, let deployEnterFee as DeployEnterFee):
            let yieldModule = try await yieldSupplyProvider.calculateYieldContract()

            guard let balance = tokenBalanceProvider.balanceType.value,
                  let balanceBigUInt = BigUInt(decimal: balance * blockchain.decimalValue) else {
                throw YieldModuleError.balanceNotFound
            }

            let deployTransactions = try await transactionProvider.deployTransactions(
                yieldModule: yieldModule,
                balance: balanceBigUInt,
                address: walletAddress,
                contractAddress: token.contractAddress,
                fee: deployEnterFee
            )

            transactions.append(contentsOf: deployTransactions)
        case (.deployed(let deployed), let fee):
            switch (deployed.initializationState, fee) {
            case (.notInitialized, let initFee as InitEnterFee):
                let initTransactions = try await transactionProvider.initTransactions(
                    contractAddress: token.contractAddress,
                    yieldModule: deployed.yieldModule,
                    fee: initFee
                )

                transactions.append(contentsOf: initTransactions)
            case (.initialized(.notActive), let reactivateFee as ReactivateEnterFee):
                let reactivateTransactions = try await transactionProvider.reactivateTransactions(
                    contractAddress: token.contractAddress,
                    yieldModule: deployed.yieldModule,
                    fee: reactivateFee
                )

                transactions.append(contentsOf: reactivateTransactions)
            case (.initialized, let enterFee as EnterFee):
                let enterTransactions = try await transactionProvider.enterTransactions(
                    contractAddress: token.contractAddress,
                    yieldModule: deployed.yieldModule,
                    fee: enterFee
                )

                transactions.append(contentsOf: enterTransactions)
            default:
                throw YieldModuleError.inconsistentState
            }
        default: throw YieldModuleError.inconsistentState
        }

        return try await transactionDispatcher
            .send(transactions: transactions.map(SendTransactionType.transfer))
            .map(\.hash)
    }

    func exitFee(yieldModule: String) async throws -> any YieldTransactionFee {
        try await transactionFeeProvider.exitFee(yieldModule: yieldModule, contractAddress: token.contractAddress)
    }

    func exit(yieldModule: String, fee: YieldTransactionFee) async throws -> [String] {
        let yieldModuleState = try await getYieldModuleState()

        guard case .deployed(let deployedState) = yieldModuleState,
              case .initialized(let activeState) = deployedState.initializationState,
              case .active = activeState,
              let exitFee = fee as? ExitFee else {
            throw YieldModuleError.yieldIsNotActive
        }

        let transactions = try await transactionProvider.exitTransactions(
            contractAddress: token.contractAddress,
            yieldModule: yieldModule,
            fee: exitFee
        )

        return try await transactionDispatcher
            .send(transactions: transactions.map(SendTransactionType.transfer))
            .map(\.hash)
    }
}

private extension CommonYieldModuleWalletManager {
    private func bind() {}

    func getAPY() async throws -> Decimal {
        try await yieldSupplyProvider.getAPY(for: token.contractAddress)
    }

    func getYieldModuleState() async throws -> YieldModuleSmartContractState {
        let yieldModule = try? await yieldSupplyProvider.getYieldContract()

        if let yieldModule {
            let yieldSupplyStatus = try await yieldSupplyProvider.getYieldSupplyStatus(
                tokenContractAddress: token.contractAddress
            )

            let maxNetworkFee = yieldSupplyStatus.maxNetworkFee

            let initializationState: YieldModuleSmartContractState.InitializationState
            if yieldSupplyStatus.initialized {
                if yieldSupplyStatus.active {
                    let balance = try? await yieldSupplyProvider.getBalance(
                        yieldSupplyStatus: yieldSupplyStatus,
                        token: token
                    )
                    initializationState = .initialized(
                        activeState: .active(
                            info: YieldModuleSmartContractState.ActiveStateInfo(
                                balance: balance,
                                maxNetworkFee: maxNetworkFee
                            )
                        )
                    )
                } else {
                    initializationState = .initialized(activeState: .notActive)
                }
            } else {
                initializationState = .notInitialized
            }
            return .deployed(.init(yieldModule: yieldModule, initializationState: initializationState))
        } else {
            return .notDeployed
        }
    }
}
