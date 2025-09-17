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

    func exitFee() async throws -> YieldTransactionFee
    func exit(fee: YieldTransactionFee) async throws -> [String]
}

enum YieldModuleWalletManagerState {
    case disabled
    case loading
    case enabled(YieldModuleWalletManagerStateInfo)
    case failedToLoad(error: String)

    var balance: Amount? {
        if case .enabled(let value) = self {
            return value.yieldSupply
        }
        return nil
    }
}

struct YieldModuleWalletManagerStateInfo {
    let apy: Decimal
    let activeState: YieldModuleActiveState
    let yieldSupply: Amount?
}

final class CommonYieldModuleWalletManager {
    private let walletModel: any WalletModel
    private let token: Token
    private let blockchain: Blockchain
    private let yieldSupplyProvider: YieldSupplyProvider
    private let tokenBalanceProvider: TokenBalanceProvider
    private let transactionDispatcher: TransactionDispatcher

    private let allowanceChecker: AllowanceChecker
    private let transactionProvider: YieldTransactionProvider
    private let transactionFeeProvider: YieldTransactionFeeProvider

    private var _state = CurrentValueSubject<YieldModuleWalletManagerState?, Error>(nil)

    private var bag = Set<AnyCancellable>()

    init(
        walletModel: any WalletModel,
        token: Token,
        blockchain: Blockchain,
        yieldSupplyProvider: YieldSupplyProvider,
        tokenBalanceProvider: TokenBalanceProvider,
        ethereumNetworkProvider: EthereumNetworkProvider,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder,
        transactionCreator: TransactionCreator,
        transactionDispatcher: TransactionDispatcher
    ) throws {
        self.walletModel = walletModel
        self.token = token
        self.blockchain = blockchain
        self.yieldSupplyProvider = yieldSupplyProvider
        self.tokenBalanceProvider = tokenBalanceProvider
        self.transactionDispatcher = transactionDispatcher

        let yieldSupplyContractAddresses = try yieldSupplyProvider.getYieldSupplyContractAddresses()

        transactionProvider = YieldTransactionProvider(
            token: token,
            blockchain: blockchain,
            transactionCreator: transactionCreator,
            transactionBuilder: ethereumTransactionDataBuilder,
            yieldSupplyContractAddresses: yieldSupplyContractAddresses
        )

        allowanceChecker = AllowanceChecker(
            blockchain: blockchain,
            amountType: .token(value: token),
            walletAddress: walletModel.defaultAddressString,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionDataBuilder: ethereumTransactionDataBuilder
        )

        transactionFeeProvider = YieldTransactionFeeProvider(
            blockchain: blockchain,
            ethereumNetworkProvider: ethereumNetworkProvider,
            allowanceChecker: allowanceChecker,
            yieldSupplyContractAddresses: yieldSupplyContractAddresses
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
        walletModel.update(silent: true)
    }

    func enterFee() async throws -> YieldTransactionFee {
        let yieldTokenState = try await getYieldModuleState()

        switch yieldTokenState {
        case .notDeployed:
            return try await transactionFeeProvider.deployFee(
                address: walletModel.defaultAddressString,
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
                    address: walletModel.defaultAddressString,
                    yieldModule: deployed.yieldModule,
                    balance: balance
                )
            case .initialized(.notActive):
                return try await transactionFeeProvider.reactivateFee(
                    address: walletModel.defaultAddressString,
                    yieldModule: deployed.yieldModule,
                    balance: balance
                )
            case .initialized(.active):
                return try await transactionFeeProvider.enterFee(
                    address: walletModel.defaultAddressString,
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
                address: walletModel.defaultAddressString,
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

    func exitFee() async throws -> any YieldTransactionFee {
        let yieldModule = try await yieldSupplyProvider.getYieldContract()
        return try await transactionFeeProvider.exitFee(yieldModule: yieldModule, contractAddress: token.contractAddress)
    }

    func exit(fee: YieldTransactionFee) async throws -> [String] {
        let yieldModuleState = try await getYieldModuleState()

        guard case .deployed(let deployedState) = yieldModuleState,
              case .initialized(let activeState) = deployedState.initializationState,
              case .active = activeState,
              let exitFee = fee as? ExitFee else {
            throw YieldModuleError.yieldIsNotActive
        }

        let transactions = try await transactionProvider.exitTransactions(
            contractAddress: token.contractAddress,
            yieldModule: deployedState.yieldModule,
            fee: exitFee
        )

        return try await transactionDispatcher
            .send(transactions: transactions.map(SendTransactionType.transfer))
            .map(\.hash)
    }
}

private extension CommonYieldModuleWalletManager {
    private func bind() {
        walletModel.statePublisher
            .withWeakCaptureOf(self)
            .asyncMap { yieldModuleWalletManager, input in
                try? await yieldModuleWalletManager.mapWalletModelState(input)
            }
            .replaceError(with: .disabled)
            .sink { [_state] state in
                _state.send(state)
            }
            .store(in: &bag)
    }

    func mapWalletModelState(_ walletModelState: WalletModelState) async throws -> YieldModuleWalletManagerState {
        switch walletModelState {
        case .created, .loading:
            return .loading
        case .loaded(let state):
            guard let yieldSupply = walletModel.yieldSupply, let yieldSupplyBalance = walletModel.yieldSupplyBalance else {
                return .disabled
            }
            return try await .enabled(
                .init(
                    apy: getAPY(),
                    activeState: .active,
                    yieldSupply: Amount(
                        with: blockchain,
                        type: .tokenYieldSupply(yieldSupply),
                        value: yieldSupplyBalance
                    )
                )
            )
        case .noAccount(message: let message, amountToCreate: let amountToCreate):
            return .disabled
        case .failed(error: let error):
            return .failedToLoad(error: error)
        }
    }

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
