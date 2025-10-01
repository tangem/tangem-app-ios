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
    var state: YieldModuleManagerStateInfo? { get }
    var statePublisher: AnyPublisher<YieldModuleManagerStateInfo?, Never> { get }

    func enterFee() async throws -> YieldTransactionFee
    func enter(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String]

    func exitFee() async throws -> YieldTransactionFee
    func exit(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String]
}

protocol YieldModuleManagerUpdater {
    func updateState(
        walletModelState: WalletModelState,
        balance: Amount?
    )
}

final class CommonYieldModuleManager {
    @Injected(\.yieldModuleMarketsManager) private var yieldModuleMarketsManager: YieldModuleMarketsManager
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private let walletAddress: String
    private let token: Token
    private let blockchain: Blockchain
    private let yieldSupplyService: YieldSupplyService
    private let tokenBalanceProvider: TokenBalanceProvider

    private let transactionProvider: YieldTransactionProvider
    private let transactionFeeProvider: YieldTransactionFeeProvider

    private var _state = CurrentValueSubject<YieldModuleManagerStateInfo?, Never>(nil)
    private var _walletModelData = CurrentValueSubject<WalletModelData?, Never>(nil)

    private var bag = Set<AnyCancellable>()

    init?(
        walletAddress: String,
        token: Token,
        blockchain: Blockchain,
        yieldSupplyService: YieldSupplyService,
        tokenBalanceProvider: TokenBalanceProvider,
        ethereumNetworkProvider: EthereumNetworkProvider,
        transactionCreator: TransactionCreator,
        blockaidApiService: BlockaidAPIService
    ) {
        guard let yieldSupplyContractAddresses = try? yieldSupplyService.getYieldSupplyContractAddresses() else {
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
            yieldSupplyContractAddresses: yieldSupplyContractAddresses,
        )

        transactionFeeProvider = YieldTransactionFeeProvider(
            walletAddress: walletAddress,
            blockchain: blockchain,
            ethereumNetworkProvider: ethereumNetworkProvider,
            blockaidApiService: blockaidApiService,
            yieldSupplyContractAddresses: yieldSupplyContractAddresses,
        )

        bind()
    }
}

extension CommonYieldModuleManager: YieldModuleManager, YieldModuleManagerUpdater {
    var state: YieldModuleManagerStateInfo? {
        _state.value
    }

    var statePublisher: AnyPublisher<YieldModuleManagerStateInfo?, Never> {
        _state
            .receiveOnMain()
            .eraseToAnyPublisher()
    }

    func updateState(
        walletModelState: WalletModelState,
        balance: Amount?
    ) {
        let data = WalletModelData(
            state: walletModelState,
            balance: balance
        )
        _walletModelData.send(data)
    }

    func enterFee() async throws -> YieldTransactionFee {
        let yieldTokenState = try await getYieldModuleState()

        let maxTokenNetworkFee = try await maxTokenNetworkFee()

        switch yieldTokenState {
        case .notDeployed:
            let yieldContractAddress = try await yieldSupplyService.calculateYieldContract()

            return try await transactionFeeProvider.deployFee(
                yieldContractAddress: yieldContractAddress,
                tokenContractAddress: token.contractAddress,
                maxNetworkFee: maxTokenNetworkFee
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
                    maxNetworkFee: maxTokenNetworkFee
                )
            case .initialized(.notActive):
                return try await transactionFeeProvider.reactivateFee(
                    yieldContractAddress: deployed.yieldModule,
                    tokenContractAddress: token.contractAddress,
                    balance: balance,
                    maxNetworkFee: maxTokenNetworkFee
                )
            case .initialized(.active):
                throw YieldModuleError.yieldIsAlreadyActive
            }
        }
    }

    func enter(fee: any YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String] {
        let yieldTokenState = try await getYieldModuleState()

        let maxTokenNetworkFee = try await maxTokenNetworkFee()

        var transactions = [Transaction]()

        switch (yieldTokenState, fee) {
        case (.notDeployed, let deployEnterFee as DeployEnterFee):
            let yieldModule = try await yieldSupplyService.calculateYieldContract()

            let deployTransactions = try await transactionProvider.deployTransactions(
                walletAddress: walletAddress,
                tokenContractAddress: token.contractAddress,
                yieldContractAddress: yieldModule,
                maxNetworkFee: maxTokenNetworkFee,
                fee: deployEnterFee
            )

            transactions.append(contentsOf: deployTransactions)
        case (.deployed(let deployed), let fee):
            switch (deployed.initializationState, fee) {
            case (.notInitialized, let initFee as InitEnterFee):
                let initTransactions = try await transactionProvider.initTransactions(
                    tokenContractAddress: token.contractAddress,
                    yieldContractAddress: deployed.yieldModule,
                    maxNetworkFee: maxTokenNetworkFee,
                    fee: initFee
                )

                transactions.append(contentsOf: initTransactions)
            case (.initialized(.notActive), let reactivateFee as ReactivateEnterFee):
                let reactivateTransactions = try await transactionProvider.reactivateTransactions(
                    tokenContractAddress: token.contractAddress,
                    yieldContractAddress: deployed.yieldModule,
                    maxNetworkFee: maxTokenNetworkFee,
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
        _walletModelData
            .compactMap { $0 }
            .combineLatest(
                yieldModuleMarketsManager.marketsPublisher.removeDuplicates()
            )
            .withWeakCaptureOf(self)
            .map { result -> YieldModuleManagerStateInfo in
                let (moduleManager, (walletModelData, marketsInfo)) = result
                return moduleManager.mapResults(
                    walletModelData: walletModelData,
                    marketsInfo: marketsInfo
                )
            }
            .removeAllDuplicates()
            .sink { [_state] result in
                _state.send(result)
            }
            .store(in: &bag)
    }

    func mapResults(
        walletModelData: WalletModelData,
        marketsInfo: [YieldModuleMarketInfo]
    ) -> YieldModuleManagerStateInfo {
        let marketInfo = marketsInfo.first(where: { $0.tokenContractAddress == token.contractAddress })

        let state: YieldModuleManagerState

        switch (walletModelData.state, marketInfo) {
        case (_, .some(let marketInfo)) where !marketInfo.isActive:
            state = .disabled
        case (.created, _), (.loading, _):
            state = .loading
        case (.loaded, _):
            if let balance = walletModelData.balance,
               case .token(let token) = balance.type,
               let yieldSupply = token.metadata.yieldSupply,
               let allowance = EthereumUtils.parseEthereumDecimal(
                   yieldSupply.allowance,
                   decimalsCount: token.decimalCount
               ) {
                state = .active(
                    YieldSupplyInfo(
                        yieldContractAddress: yieldSupply.yieldContractAddress,
                        balance: balance,
                        allowance: allowance
                    )
                )
            } else {
                state = .notActive
            }
        case (.noAccount, _):
            state = .disabled
        case (.failed(error: let error), _):
            state = .failedToLoad(error: error)
        }

        return YieldModuleManagerStateInfo(marketInfo: marketInfo, state: state)
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

    func maxTokenNetworkFee() async throws -> BigUInt {
        guard let maxCoinNetworkFeeDecimal = state?.marketInfo?.maxNetworkFee.decimal,
              let tokenCurrencyId = token.id else {
            throw YieldModuleError.maxNetworkFeeNotFound
        }

        let coinPrice = try await quotesRepository.quote(for: blockchain.currencyId)
        let tokenPrice = try await quotesRepository.quote(for: tokenCurrencyId)

        let maxNetworkFeeToken = maxCoinNetworkFeeDecimal * coinPrice.price / tokenPrice.price

        return BigUInt(stringLiteral: maxNetworkFeeToken.stringValue)
    }
}

struct WalletModelData {
    let state: WalletModelState
    let balance: Amount?
}

private extension Amount {
    var tokenYieldSupply: TokenYieldSupply? {
        guard case .token(let token) = type else { return nil }
        return token.metadata.yieldSupply
    }
}
