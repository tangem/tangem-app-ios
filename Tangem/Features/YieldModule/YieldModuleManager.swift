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
import TangemFoundation

protocol YieldModuleManager {
    var state: YieldModuleManagerState? { get }
    var statePublisher: AnyPublisher<YieldModuleManagerState?, Never> { get }

    func enterFee() async throws -> YieldTransactionFee
    func enter(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String]

    func exitFee() async throws -> YieldTransactionFee
    func exit(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String]
}

protocol YieldModuleManagerUpdater {
    func updateState(walletModelState: WalletModelState, balance: Amount?) async
}

enum YieldModuleManagerState {
    case disabled
    case loading
    case notActive(apy: Decimal)
    case active(YieldModuleManagerStateInfo)
    case failedToLoad(error: String)

    var balance: Amount? {
        if case .active(let value) = self {
            return value.yieldSupply
        }
        return nil
    }
}

struct YieldModuleManagerStateInfo {
    let apy: Decimal
    let activeState: YieldModuleActiveState
    let yieldSupply: Amount?
}

final class CommonYieldModuleManager {
    private let walletAddress: String
    private let token: Token
    private let blockchain: Blockchain
    private let yieldSupplyService: YieldSupplyService
    private let tokenBalanceProvider: TokenBalanceProvider

    private let transactionProvider: YieldTransactionProvider
    private let transactionFeeProvider: YieldTransactionFeeProvider

    private var _state = CurrentValueSubject<YieldModuleManagerState?, Never>(nil)

    private var bag = Set<AnyCancellable>()

    init?(
        walletAddress: String,
        token: Token,
        blockchain: Blockchain,
        yieldSupplyService: YieldSupplyService,
        tokenBalanceProvider: TokenBalanceProvider,
        ethereumNetworkProvider: EthereumNetworkProvider,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder,
        transactionCreator: TransactionCreator,
        blockaidApiService: BlockaidAPIService
    ) {
        guard let yieldSupplyContractAddresses = try? yieldSupplyService.getYieldSupplyContractAddresses(),
              let maxNetworkFee = BigUInt(decimal: Constants.maxNetworkFee * blockchain.decimalValue) else {
            return nil
        }

        self.walletAddress = walletAddress
        self.token = token
        self.blockchain = blockchain
        self.yieldSupplyService = yieldSupplyService
        self.tokenBalanceProvider = tokenBalanceProvider

        transactionProvider = YieldTransactionProvider(
            token: token,
            blockchain: blockchain,
            transactionCreator: transactionCreator,
            transactionBuilder: ethereumTransactionDataBuilder,
            yieldSupplyContractAddresses: yieldSupplyContractAddresses,
            maxNetworkFee: maxNetworkFee
        )

        transactionFeeProvider = YieldTransactionFeeProvider(
            walletAddress: walletAddress,
            blockchain: blockchain,
            ethereumNetworkProvider: ethereumNetworkProvider,
            blockaidApiService: blockaidApiService,
            yieldSupplyContractAddresses: yieldSupplyContractAddresses,
            maxNetworkFee: maxNetworkFee
        )
    }
}

extension CommonYieldModuleManager: YieldModuleManager, YieldModuleManagerUpdater {
    var state: YieldModuleManagerState? {
        _state.value
    }

    var statePublisher: AnyPublisher<YieldModuleManagerState?, Never> {
        _state
            .receiveOnMain()
            .eraseToAnyPublisher()
    }

    func updateState(walletModelState: WalletModelState, balance: Amount?) async {
        do {
            let newState = try await mapWalletModelState(walletModelState, balance: balance)
            _state.send(newState)
        } catch {
            _state.send(.failedToLoad(error: error.localizedDescription))
        }
    }

    func enterFee() async throws -> YieldTransactionFee {
        let yieldTokenState = try await getYieldModuleState()

        switch yieldTokenState {
        case .notDeployed:
            let yieldContractAddress = try await yieldSupplyService.calculateYieldContract()

            return try await transactionFeeProvider.deployFee(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: token.contractAddress
            )
        case .deployed(let deployed):
            guard let balance = tokenBalanceProvider.balanceType.value else {
                throw YieldModuleError.balanceNotFound
            }

            switch deployed.initializationState {
            case .notInitialized:
                return try await transactionFeeProvider.initializeFee(
                    yieldContractAddress: deployed.yieldModule,
                    tokenContractAddress: token.contractAddress,
                )
            case .initialized(.notActive):
                return try await transactionFeeProvider.reactivateFee(
                    yieldContractAddress: deployed.yieldModule,
                    tokenContractAddress: token.contractAddress,
                    balance: balance
                )
            case .initialized(.active):
                throw YieldModuleError.yieldIsAlreadyActive
            }
        }
    }

    func enter(fee: any YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String] {
        let yieldTokenState = try await getYieldModuleState()

        var transactions = [Transaction]()

        switch (yieldTokenState, fee) {
        case (.notDeployed, let deployEnterFee as DeployEnterFee):
            let yieldModule = try await yieldSupplyService.calculateYieldContract()

            let deployTransactions = try await transactionProvider.deployTransactions(
                walletAddress: walletAddress,
                tokenContractAddress: token.contractAddress,
                yieldContractAddress: yieldModule,
                fee: deployEnterFee
            )

            transactions.append(contentsOf: deployTransactions)
        case (.deployed(let deployed), let fee):
            switch (deployed.initializationState, fee) {
            case (.notInitialized, let initFee as InitEnterFee):
                let initTransactions = try await transactionProvider.initTransactions(
                    tokenContractAddress: token.contractAddress,
                    yieldContractAddress: deployed.yieldModule,
                    fee: initFee
                )

                transactions.append(contentsOf: initTransactions)
            case (.initialized(.notActive), let reactivateFee as ReactivateEnterFee):
                let reactivateTransactions = try await transactionProvider.reactivateTransactions(
                    tokenContractAddress: token.contractAddress,
                    yieldContractAddress: deployed.yieldModule,
                    fee: reactivateFee
                )

                transactions.append(contentsOf: reactivateTransactions)
            case (.initialized, _):
                throw YieldModuleError.yieldIsAlreadyActive
            default:
                throw YieldModuleError.inconsistentState
            }
        default: throw YieldModuleError.inconsistentState
        }

        return try await transactionDispatcher
            .send(transactions: transactions.map(TransactionDispatcherTransactionType.transfer))
            .map(\.hash)
    }

    func exitFee() async throws -> any YieldTransactionFee {
        let yieldContractAddress = try await yieldSupplyService.getYieldContract()
        return try await transactionFeeProvider.exitFee(
            yieldContractAddress: yieldContractAddress,
            tokenContractAddress: token.contractAddress
        )
    }

    func exit(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String] {
        let yieldModuleState = try await getYieldModuleState()

        guard case .deployed(let deployedState) = yieldModuleState,
              case .initialized(let activeState) = deployedState.initializationState,
              case .active = activeState,
              let exitFee = fee as? ExitFee else {
            throw YieldModuleError.yieldIsNotActive
        }

        let transactions = try await transactionProvider.exitTransactions(
            tokenContractAddress: token.contractAddress,
            yieldContractAddress: deployedState.yieldModule,
            fee: exitFee
        )

        return try await transactionDispatcher
            .send(transactions: transactions.map(TransactionDispatcherTransactionType.transfer))
            .map(\.hash)
    }
}

private extension CommonYieldModuleManager {
    func mapWalletModelState(_ walletModelState: WalletModelState, balance: Amount?) async throws -> YieldModuleManagerState {
        let apy = Decimal(stringValue: "0.25")! // will be taken from backend response in the future
        switch walletModelState {
        case .created, .loading:
            return .loading
        case .loaded:
            guard let balance,
                  case .token(let token) = balance.type,
                  token.metadata.yieldSupply != nil else {
                return .notActive(apy: apy)
            }
            return .active(
                .init(
                    apy: apy,
                    activeState: .active, // will be taken from backend response later
                    yieldSupply: balance
                )
            )
        case .noAccount:
            return .disabled
        case .failed(error: let error):
            return .failedToLoad(error: error)
        }
    }

    func getYieldModuleState() async throws -> YieldModuleSmartContractState {
        let yieldModule = try? await yieldSupplyService.getYieldContract()

        if let yieldModule {
            let yieldSupplyStatus = try await yieldSupplyService.getYieldSupplyStatus(
                tokenContractAddress: token.contractAddress
            )

            let maxNetworkFee = yieldSupplyStatus.maxNetworkFee

            let initializationState: YieldModuleSmartContractState.InitializationState
            if yieldSupplyStatus.initialized {
                if yieldSupplyStatus.active {
                    let balance = try? await yieldSupplyService.getBalance(
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

extension CommonYieldModuleManager {
    enum Constants {
        static let maxNetworkFee = Decimal(stringValue: "0.5")! // temp value, will be taken from backend response later
    }
}
