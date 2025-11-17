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

    func approveFee() async throws -> YieldTransactionFee
    func approve(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> String

    func minimalFee() async throws -> Decimal
    func currentNetworkFee() async throws -> Decimal

    func fetchYieldTokenInfo() async throws -> YieldModuleTokenInfo
    func fetchChartData() async throws -> YieldChartData

    func sendActivationState()
}

protocol YieldModuleManagerUpdater {
    func updateState(
        walletModelState: WalletModelState,
        balance: Amount?
    )
}

final class CommonYieldModuleManager {
    @Injected(\.yieldModuleNetworkManager) private var yieldModuleNetworkManager: YieldModuleNetworkManager
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    private let walletAddress: String
    private let token: Token
    private let blockchain: Blockchain
    private let chainId: Int
    private let tokenId: String
    private let yieldSupplyService: YieldSupplyService
    private let userWalletId: String

    private let transactionProvider: YieldTransactionProvider
    private let transactionFeeProvider: YieldTransactionFeeProvider

    private let yieldModuleStateRepository: YieldModuleStateRepository
    private let yieldModuleStateMapper: YieldModuleStateMapper

    private var _state = CurrentValueSubject<YieldModuleManagerStateInfo?, Never>(nil)
    private var _walletModelData = CurrentValueSubject<WalletModelData?, Never>(nil)

    private var pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never>

    private var forceIgnoreUpdates = false
    private var stateCheckTimer: Timer?

    private var bag = Set<AnyCancellable>()

    private let updateWallet: () -> Void

    init?(
        walletAddress: String,
        userWalletId: String,
        token: Token,
        blockchain: Blockchain,
        yieldSupplyService: YieldSupplyService,
        tokenBalanceProvider: TokenBalanceProvider,
        ethereumNetworkProvider: EthereumNetworkProvider,
        transactionCreator: TransactionCreator,
        blockaidApiService: BlockaidAPIService,
        yieldModuleStateRepository: YieldModuleStateRepository,
        pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never>,
        updateWallet: @escaping () -> Void
    ) {
        guard let yieldSupplyContractAddresses = try? yieldSupplyService.getYieldSupplyContractAddresses(),
              let chainId = blockchain.chainId,
              let tokenId = token.id
        else {
            return nil
        }

        self.walletAddress = walletAddress
        self.userWalletId = userWalletId
        self.token = token
        self.blockchain = blockchain
        self.chainId = chainId
        self.tokenId = tokenId
        self.yieldSupplyService = yieldSupplyService
        self.yieldModuleStateRepository = yieldModuleStateRepository
        self.pendingTransactionsPublisher = pendingTransactionsPublisher
        self.updateWallet = updateWallet

        yieldModuleStateMapper = YieldModuleStateMapper(token: token)

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
            tokenBalanceProvider: tokenBalanceProvider
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

    func currentNetworkFee() async throws -> Decimal {
        try await transactionFeeProvider.currentNetworkFee()
    }

    func minimalFee() async throws -> Decimal {
        try await transactionFeeProvider.minimalFee(tokenId: tokenId)
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
                    tokenDecimalCount: token.decimalCount,
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

        let result = try await transactionDispatcher
            .send(transactions: transactions.map(TransactionDispatcherTransactionType.transfer))
            .map(\.hash)

        startStateCheckTimer()

        try? await yieldModuleNetworkManager.activate(
            tokenContractAddress: token.contractAddress,
            walletAddress: walletAddress,
            chainId: chainId,
            userWalletId: userWalletId
        )

        await activate()

        return result
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

        let result = try await transactionDispatcher
            .send(transactions: transactions.map(TransactionDispatcherTransactionType.transfer))
            .map(\.hash)

        startStateCheckTimer()

        await deactivate()

        return result
    }

    func approveFee() async throws -> any YieldTransactionFee {
        try await transactionFeeProvider.approveFee(
            yieldContractAddress: try await yieldSupplyService.getYieldContract(),
            tokenContractAddress: token.contractAddress
        )
    }

    func approve(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> String {
        let yieldModuleState = try await getYieldModuleState()

        guard case .deployed(let deployedState) = yieldModuleState,
              let approveFee = fee as? ApproveFee else {
            throw YieldModuleError.yieldIsNotActive
        }

        let transaction = try await transactionProvider.approveTransaction(
            tokenContractAddress: token.contractAddress,
            yieldContractAddress: deployedState.yieldModule,
            fee: approveFee.fee
        )

        return try await transactionDispatcher
            .send(transaction: .transfer(transaction)).hash
    }

    func fetchYieldTokenInfo() async throws -> YieldModuleTokenInfo {
        try await yieldModuleNetworkManager.fetchYieldTokenInfo(
            tokenContractAddress: token.contractAddress,
            chainId: chainId
        )
    }

    func fetchChartData() async throws -> YieldChartData {
        try await yieldModuleNetworkManager.fetchChartData(tokenContractAddress: token.contractAddress, chainId: chainId)
    }

    func sendActivationState() {
        Task {
            switch state?.state {
            case .active:
                await activate()
            case .notActive:
                await deactivate()
            default:
                break
            }
        }
    }
}

private extension CommonYieldModuleManager {
    func bind() {
        let yieldContractPublisher: AnyPublisher<String?, Never> = Future
            .async {
                let yieldContract = try? await self.yieldSupplyService.getYieldContract()
                if yieldContract == nil || yieldContract?.isEmpty == true {
                    return try await self.yieldSupplyService.calculateYieldContract()
                }
                return yieldContract
            }
            .retry(Constants.yieldContractRetryCount)
            .replaceError(with: nil)
            .eraseToAnyPublisher()

        let walletModelDataPublisher = _walletModelData.compactMap { $0 }

        let marketsPublisher = yieldModuleNetworkManager.marketsPublisher.filter { !$0.isEmpty }.removeDuplicates()

        let pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never> = pendingTransactionsPublisher
            .map { transactions in
                transactions.filter { record -> Bool in
                    switch record.status {
                    case .none, .pending: true
                    default: false
                    }
                }
            }
            .eraseToAnyPublisher()

        let statePublisher = Publishers.CombineLatest4(
            walletModelDataPublisher,
            marketsPublisher,
            pendingTransactionsPublisher,
            yieldContractPublisher
        )
        .map { [yieldModuleStateMapper, yieldModuleStateRepository] result -> YieldModuleManagerStateInfo in
            yieldModuleStateMapper.map(
                walletModelData: result.0,
                marketsInfo: result.1,
                pendingTransactions: result.2,
                yieldModuleStateRepository: yieldModuleStateRepository,
                yieldContract: result.3
            )
        }
        .filter { [weak self] stateInfo in
            // premature updates could lead to inconsistent state
            // for example when transactions are already executed but yield module
            // didn't update it's state to active on chain
            switch stateInfo.state {
            case .processing: true // always pass processing state
            default: self?.forceIgnoreUpdates == false
            }
        }
        .removeDuplicates()

        statePublisher
            .handleEvents(
                receiveOutput: { [weak self] in
                    self?.updateStateCacheIfNeeded(state: $0)
                }
            )
            .sink { [_state] state in
                _state.send(state)
            }
            .store(in: &bag)
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
        guard let marketInfo = state?.marketInfo,
              let maxFeeNative = marketInfo.maxFeeNative,
              let tokenCurrencyId = token.id
        else {
            throw YieldModuleError.maxNetworkFeeNotFound
        }

        let maxFeeNativeWei = maxFeeNative * blockchain.decimalValue
        let coinPrice = try await quotesRepository.quote(for: blockchain.currencyId)
        let tokenPrice = try await quotesRepository.quote(for: tokenCurrencyId)

        let maxNetworkFeeToken = maxFeeNativeWei * coinPrice.price / tokenPrice.price

        return EthereumUtils.mapToBigUInt(maxNetworkFeeToken)
    }

    func activate() async {
        try? await yieldModuleNetworkManager.activate(
            tokenContractAddress: token.contractAddress,
            walletAddress: walletAddress,
            chainId: chainId,
            userWalletId: userWalletId
        )
    }

    func deactivate() async {
        try? await yieldModuleNetworkManager.deactivate(
            tokenContractAddress: token.contractAddress,
            walletAddress: walletAddress,
            chainId: chainId
        )
    }

    func startStateCheckTimer() {
        AppLogger.debug("Start yield module state tracking")

        stateCheckTimer?.invalidate()
        forceIgnoreUpdates = true // ignore updates for the first 10 seconds to avoid inconsistent state

        let timer = Timer(timeInterval: Constants.updateTimeInterval, repeats: true) { [weak self] _ in
            guard let self else { return }

            forceIgnoreUpdates = false // reset flag after 10 seconds

            if case .processing = state?.state {
                updateWallet()
            } else {
                AppLogger.debug("Stop yield module state tracking")
                stateCheckTimer?.invalidate()
                stateCheckTimer = nil
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        stateCheckTimer = timer
    }
}

private extension CommonYieldModuleManager {
    func updateStateCacheIfNeeded(state: YieldModuleManagerStateInfo) {
        switch state.state {
        case .disabled:
            yieldModuleStateRepository.clearState()
        case .processing, .active, .notActive:
            yieldModuleStateRepository.storeState(state.state)
        default: break
        }
    }
}

struct WalletModelData {
    let state: WalletModelState
    let balance: Amount?
}

private extension CommonYieldModuleManager {
    enum Constants {
        static let yieldContractRetryCount = 5
        static let updateTimeInterval: TimeInterval = 10
    }
}
