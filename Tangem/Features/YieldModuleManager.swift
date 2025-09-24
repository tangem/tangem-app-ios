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
    func updateState(walletModelState: WalletModelState, balance: Amount?)
}

final class CommonYieldModuleManager {
    @Injected(\.yieldModuleMarketsManager) private var yieldModuleMarketsManager: YieldModuleMarketsManager

    private let walletAddress: String
    private let token: Token
    private let blockchain: Blockchain
    private let yieldSupplyService: YieldSupplyService
    private let tokenBalanceProvider: TokenBalanceProvider

    private let transactionProvider: YieldTransactionProvider
    private let transactionFeeProvider: YieldTransactionFeeProvider

    private var _state = CurrentValueSubject<YieldModuleManagerState?, Never>(nil)
    private var _walletModelState = CurrentValueSubject<(WalletModelState, Amount?)?, Never>(nil)

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
              let maxNetworkFee = BigUInt(decimal: YieldConstants.maxNetworkFee * blockchain.decimalValue) else {
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

        bind()
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

    func updateState(walletModelState: WalletModelState, balance: Amount?) {
        _walletModelState.send((walletModelState, balance))
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
    func bind() {
        _walletModelState
            .compactMap { $0 }
            .combineLatest(yieldModuleMarketsManager.marketsPublisher.removeDuplicates())
            .withWeakCaptureOf(self)
            .map { result -> YieldModuleManagerState in
                let (moduleManager, (walletModelState, marketsInfo)) = result
                return moduleManager.mapWalletModelState(
                    walletModelState.0,
                    balance: walletModelState.1,
                    marketsInfo: marketsInfo
                )
            }
            .sink { [_state] result in
                _state.send(result)
            }
            .store(in: &bag)
    }

    func mapWalletModelState(
        _ walletModelState: WalletModelState,
        balance: Amount?,
        marketsInfo: [YieldModuleMarketInfo]
    ) -> YieldModuleManagerState {
        let marketInfo = marketsInfo.first(where: { $0.tokenContractAddress == token.contractAddress })

        switch (walletModelState, marketInfo) {
        case (_, .some(let marketInfo)) where !marketInfo.isActive:
            return .disabled
        case (.created, _), (.loading, _):
            return .loading
        case (.loaded, let marketInfo):
            guard case .token(let token) = balance?.type,
                  case .yield = token.metadata.kind else {
                return .notActive(apy: marketInfo?.apy)
            }
            return .active(.init(marketInfo: marketInfo, amount: balance))
        case (.noAccount, _):
            return .disabled
        case (.failed(error: let error), _):
            return .failedToLoad(error: error)
        }
    }

    func getAPY() async throws -> Decimal {
        try await yieldSupplyService.getAPY(for: token.contractAddress)
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
