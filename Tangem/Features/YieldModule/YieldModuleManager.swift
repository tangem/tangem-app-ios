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

    var blockchain: Blockchain { get }
    var tokenId: String { get }

    func enterFee() async throws -> YieldTransactionFee
    func enter(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String]

    func exitFee() async throws -> YieldTransactionFee
    func exit(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String]

    func approveFee() async throws -> YieldTransactionFee
    func approve(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> String

    func currentNetworkFeeParameters() async throws -> EthereumFeeParameters

    func fetchYieldTokenInfo() async throws -> YieldModuleTokenInfo
    func fetchChartData() async throws -> YieldChartData

    func sendActivationState()
    func sendTransactionSendEvent(transactionHash: String)
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

    let blockchain: Blockchain
    let tokenId: String

    private let walletAddress: String
    private let token: Token
    private let chainId: Int
    private let yieldSupplyService: YieldSupplyService
    private let userWalletId: String

    private let transactionProvider: YieldTransactionProvider
    private let transactionFeeProvider: YieldTransactionFeeProvider

    private let yieldModuleStateRepository: YieldModuleStateRepository
    private let yieldModuleMarketsRepository: YieldModuleMarketsRepository

    private var _state = CurrentValueSubject<YieldModuleManagerStateInfo?, Never>(nil)
    private var _walletModelData = CurrentValueSubject<WalletModelData?, Never>(nil)

    private var pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never>

    private var _nextExpectedState = CurrentValueSubject<NextExpectedState?, Never>(nil)
    private var nextExpectedStateTimeoutTask: Task<Void, Never>?

    private var bag = Set<AnyCancellable>()

    private let updateWallet: () async -> Void

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
        yieldModuleMarketsRepository: YieldModuleMarketsRepository,
        pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never>,
        updateWallet: @escaping () async -> Void
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
        self.yieldModuleMarketsRepository = yieldModuleMarketsRepository
        self.pendingTransactionsPublisher = pendingTransactionsPublisher
        self.updateWallet = updateWallet

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

    func currentNetworkFeeParameters() async throws -> EthereumFeeParameters {
        try await transactionFeeProvider.currentNetworkFeeParameters()
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

        var yieldContractAddressToSave: String?

        switch (yieldTokenState, fee) {
        case (.notDeployed, let deployEnterFee as DeployEnterFee):
            let yieldContractAddress = try await yieldSupplyService.calculateYieldContract()

            let deployTransactions = try await transactionProvider.deployTransactions(
                walletAddress: walletAddress,
                tokenContractAddress: token.contractAddress,
                yieldContractAddress: yieldContractAddress,
                maxNetworkFee: maxTokenNetworkFee,
                fee: deployEnterFee
            )

            yieldContractAddressToSave = yieldContractAddress

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

        if let yieldContractAddressToSave {
            await yieldSupplyService.storeYieldContract(yieldContractAddressToSave)
        }

        await setNextExpectedState(.active)

        await activate()

        if hasEnterTransaction(in: transactions), let enterHash = result.last {
            await yieldModuleNetworkManager.sendTransactionEvent(txHash: enterHash, operation: .enter)
        }

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

        await setNextExpectedState(.notActive)

        await deactivate()

        if let exitHash = result.first {
            await yieldModuleNetworkManager.sendTransactionEvent(txHash: exitHash, operation: .exit)
        }

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

        let hash = try await transactionDispatcher
            .send(transaction: .transfer(transaction)).hash

        // active state must have isAllowancePermissionRequired == false
        await setNextExpectedState(.active)

        return hash
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

    func sendTransactionSendEvent(transactionHash: String) {
        Task { [weak self] in
            await self?.yieldModuleNetworkManager.sendTransactionEvent(txHash: transactionHash, operation: .send)
        }
    }
}

private extension CommonYieldModuleManager {
    func bind() {
        let initialStatePublisher = makeInitialStatePublisher()

        initialStatePublisher
            .handleEvents(receiveOutput: { [weak self] in
                self?.updateStateCacheIfNeeded(state: $0)
            })
            .sink { [_state] result in
                _state.send(result)
            }
            .store(in: &bag)

        pendingTransactionsPublisher
            .withPrevious()
            .withWeakCaptureOf(self)
            .asyncMap { result in
                let (moduleManager, (previous, current)) = result
                guard let previous,
                      // avoid redundant calculations if module isn't deployed
                      let storedYieldContract = await moduleManager.yieldSupplyService.storedYieldContract() else {
                    return
                }

                if moduleManager.hasEnterOrExitTransactions(in: previous, yieldContract: storedYieldContract),
                   !moduleManager.hasEnterOrExitTransactions(in: current, yieldContract: storedYieldContract) {
                    await moduleManager.updateWalletState(
                        iteration: 0,
                        maxIterations: Constants.maxUpdateIterations
                    )
                }
            }
            .sink { _ in }
            .store(in: &bag)
    }

    func mapResults(
        walletModelData: WalletModelData,
        marketsInfo: [YieldModuleMarketInfo],
        nextExpectedState: NextExpectedState?
    ) -> YieldModuleManagerStateInfo {
        let marketInfo = marketsInfo.first {
            $0.tokenContractAddress == token.contractAddress && $0.chainId == chainId
        }

        let state: YieldModuleManagerState

        switch walletModelData.state {
        case .created:
            state = .loading(cachedState: nil)
        case .loading:
            state = .loading(cachedState: yieldModuleStateRepository.state())
        case .loaded:
            if let balance = walletModelData.balance,
               case .token(let token) = balance.type,
               let yieldSupply = token.metadata.yieldSupply {
                state = .active(
                    YieldSupplyInfo(
                        yieldContractAddress: yieldSupply.yieldContractAddress,
                        balance: balance,
                        isAllowancePermissionRequired: YieldAllowanceUtil().isPermissionRequired(
                            allowance: yieldSupply.allowance
                        ),
                        yieldModuleBalanceValue: yieldSupply.protocolBalanceValue
                    )
                )
            } else {
                state = (marketInfo?.isActive ?? false) ? .notActive : .disabled
            }
        case .noAccount:
            state = .disabled
        case .failed(error: let error):
            let cachedState = yieldModuleStateRepository.state()
            if (marketInfo?.isActive ?? false) || cachedState?.isEffectivelyActive == true {
                state = .failedToLoad(error: error, cachedState: cachedState)
            } else {
                state = .disabled
            }
        }

        let result = YieldModuleManagerStateInfo(marketInfo: marketInfo, state: state)

        switch nextExpectedState {
        case .none:
            return result
        case .some where isStateExpected(newState: result.state):
            return result
        case .active:
            return YieldModuleManagerStateInfo(marketInfo: marketInfo, state: .processing(action: .enter))
        case .notActive:
            return YieldModuleManagerStateInfo(marketInfo: marketInfo, state: .processing(action: .exit))
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
}

private extension CommonYieldModuleManager {
    /// Builds the main state publisher and, if cached data is available,
    /// prepends the cached `YieldModuleManagerStateInfo` so the UI can render
    /// an immediate initial state before live updates arrive.
    func makeInitialStatePublisher() -> AnyPublisher<YieldModuleManagerStateInfo, Never> {
        let statePublisher = Publishers.CombineLatest3(
            _walletModelData.compactMap { $0 },
            yieldModuleNetworkManager.marketsPublisher.removeDuplicates(),
            _nextExpectedState.removeDuplicates(),
        )
        .withWeakCaptureOf(self)
        .map { result -> YieldModuleManagerStateInfo in
            let (moduleManager, (data, marketsInfo, nextExpectedState)) = result

            return moduleManager.mapResults(
                walletModelData: data,
                marketsInfo: marketsInfo,
                nextExpectedState: nextExpectedState
            )
        }
        .removeDuplicates()
        .eraseToAnyPublisher()

        guard let cachedMarket = yieldModuleMarketsRepository.marketInfo(for: token.contractAddress),
              let cachedState = yieldModuleStateRepository.state()
        else {
            return statePublisher
        }

        let cachedStateInfo = YieldModuleManagerStateInfo(marketInfo: .init(from: cachedMarket), state: .loading(cachedState: cachedState))
        return statePublisher
            .prepend(cachedStateInfo)
            .eraseToAnyPublisher()
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

    func updateWalletState(iteration: Int, maxIterations: Int) async {
        guard iteration < maxIterations else {
            await setNextExpectedState(nil)
            AppLogger.debug("Max iterations reached. Stopping yield module state update.")
            return
        }

        AppLogger.debug("Update yield module state")

        await updateWallet()

        if isStateExpected(newState: _state.value?.state) {
            await setNextExpectedState(nil)
        } else {
            // delay only if the next update is necessary
            try? await Task.sleep(for: .seconds(Constants.updateTimeInterval))
            await updateWalletState(iteration: iteration + 1, maxIterations: maxIterations)
        }
    }

    func isStateExpected(newState: YieldModuleManagerState?) -> Bool {
        switch (newState, _nextExpectedState.value) {
        case (.notActive, .notActive), (_, .none): true
        case (.active(let yieldSupplyInfo), .active) where !yieldSupplyInfo.isAllowancePermissionRequired: true
        default: false
        }
    }

    @MainActor
    func setNextExpectedState(_ state: NextExpectedState?) {
        // Cancel any existing timeout task
        nextExpectedStateTimeoutTask?.cancel()
        nextExpectedStateTimeoutTask = nil

        _nextExpectedState.send(state)

        // If setting a non-nil state, start a timeout to reset it
        if state != nil {
            nextExpectedStateTimeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(Constants.nextExpectedStateTimeout))
                guard !Task.isCancelled else { return }
                self?._nextExpectedState.send(nil)
                AppLogger.debug("Next expected state timed out and was reset to nil")
            }
        }
    }
}

private extension CommonYieldModuleManager {
    func hasEnterTransaction(in transactions: [Transaction]) -> Bool {
        let dummyEnterMethod = EnterProtocolMethod(tokenContractAddress: .empty)
        return hasTransaction(in: transactions, for: dummyEnterMethod)
    }

    func hasEnterOrExitTransactions(in pendingTransactions: [PendingTransactionRecord], yieldContract: String?) -> Bool {
        let dummyDeployMethod = DeployYieldModuleMethod(
            walletAddress: String(),
            tokenContractAddress: String(),
            maxNetworkFee: .zero
        )
        let dummyInitMethod = InitYieldTokenMethod(tokenContractAddress: String(), maxNetworkFee: .zero)
        let dummyEnterMethod = EnterProtocolMethod(tokenContractAddress: String())
        let dummyReactivateMethod = ReactivateTokenMethod(tokenContractAddress: String(), maxNetworkFee: .zero)
        let dummyApproveMethod = ApproveERC20TokenMethod(spender: String(), amount: .zero)
        let dummyWithdrawAndDeactivateMethod = WithdrawAndDeactivateMethod(tokenContractAddress: String())

        return hasTransactions(
            in: pendingTransactions,
            for: [
                dummyDeployMethod,
                dummyInitMethod,
                dummyReactivateMethod,
                dummyEnterMethod,
                dummyApproveMethod,
                dummyWithdrawAndDeactivateMethod,
            ],
            yieldContract: yieldContract
        )
    }

    func hasTransaction(in transactions: [Transaction], for method: SmartContractMethod) -> Bool {
        return transactions.contains { transaction in
            guard let dataHex = transaction.ethereumTransactionDataHexString() else {
                return false
            }

            return dataHex.hasPrefix(method.methodId.removeHexPrefix().lowercased())
        }
    }

    func hasTransactions(
        in pendingTransactions: [PendingTransactionRecord],
        for methods: [SmartContractMethod],
        yieldContract: String?
    ) -> Bool {
        return pendingTransactions.contains { record in
            guard let dataHex = record.ethereumTransactionDataHexString() else { return false }

            let methodMatch = methods.contains { method in
                dataHex.hasPrefix(method.methodId.removeHexPrefix().lowercased())
            }

            let tokenMatch = dataHex.contains(token.contractAddress.removeHexPrefix().lowercased())
            let yieldModuleMatch = yieldContract.flatMap { dataHex.contains($0.removeHexPrefix().lowercased()) } ?? false

            return methodMatch && (tokenMatch || yieldModuleMatch)
        }
    }
}

extension CommonYieldModuleManager {
    enum NextExpectedState {
        case active
        case notActive
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

private extension Transaction {
    func ethereumTransactionDataHexString() -> String? {
        guard let params = params as? EthereumTransactionParams,
              let data = params.data else { return nil }

        return data.hexString.lowercased()
    }
}

private extension PendingTransactionRecord {
    func ethereumTransactionDataHexString() -> String? {
        guard let params = transactionParams as? EthereumTransactionParams,
              let data = params.data else { return nil }

        return data.hexString.lowercased()
    }
}

private extension CommonYieldModuleManager {
    enum Constants {
        static let yieldContractRetryCount = 5
        static let updateTimeInterval: TimeInterval = 10
        static let maxUpdateIterations = 3
        static let nextExpectedStateTimeout: TimeInterval = 60
    }
}
