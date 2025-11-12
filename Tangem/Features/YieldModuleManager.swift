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

    private var _state = CurrentValueSubject<YieldModuleManagerStateInfo?, Never>(nil)
    private var _walletModelData = CurrentValueSubject<WalletModelData?, Never>(nil)

    private var pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never>

    private var bag = Set<AnyCancellable>()

    private let scheduleWalletUpdate: () -> Void

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
        scheduleWalletUpdate: @escaping () -> Void
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
        self.scheduleWalletUpdate = scheduleWalletUpdate

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

        try? await yieldModuleNetworkManager.activate(
            tokenContractAddress: token.contractAddress,
            walletAddress: walletAddress,
            chainId: chainId,
            userWalletId: userWalletId
        )

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

        try? await yieldModuleNetworkManager.deactivate(
            tokenContractAddress: token.contractAddress,
            walletAddress: walletAddress,
            chainId: chainId
        )

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

        let statePublisher = Publishers.CombineLatest4(
            _walletModelData.compactMap { $0 },
            yieldModuleNetworkManager.marketsPublisher.filter { !$0.isEmpty }.removeDuplicates(),
            pendingTransactionsPublisher,
            yieldContractPublisher
        )
        .withWeakCaptureOf(self)
        .map { result -> YieldModuleManagerStateInfo in
            let (moduleManager, (walletModelData, marketsInfo, pendingTransactions, yieldContract)) = result
            return moduleManager.mapResults(
                walletModelData: walletModelData,
                marketsInfo: marketsInfo,
                pendingTransactions: pendingTransactions,
                yieldContract: yieldContract
            )
        }
        .removeDuplicates()

        statePublisher
            .handleEvents(
                receiveOutput: { [weak self] in
                    self?.updateStateCacheIfNeeded(state: $0)
                }
            )
            .sink { [_state] result in
                _state.send(result)
            }
            .store(in: &bag)

        statePublisher
            .map(\.state)
            .sink { [weak self] state in
                guard case .processing = state else { return }
                self?.scheduleWalletUpdate()
            }
            .store(in: &bag)
    }

    func mapResults(
        walletModelData: WalletModelData,
        marketsInfo: [YieldModuleMarketInfo],
        pendingTransactions: [PendingTransactionRecord],
        yieldContract: String?
    ) -> YieldModuleManagerStateInfo {
        guard let marketInfo = marketsInfo.first(where: { $0.tokenContractAddress == token.contractAddress }) else {
            return YieldModuleManagerStateInfo(marketInfo: nil, state: .disabled)
        }

        guard marketInfo.isActive else {
            return YieldModuleManagerStateInfo(marketInfo: marketInfo, state: .disabled)
        }

        if hasEnterTransactions(in: pendingTransactions, yieldContract: yieldContract) {
            return YieldModuleManagerStateInfo(marketInfo: marketInfo, state: .processing(action: .enter))
        }

        if hasExitTransactions(in: pendingTransactions, yieldContract: yieldContract) {
            return YieldModuleManagerStateInfo(marketInfo: marketInfo, state: .processing(action: .exit))
        }

        let state: YieldModuleManagerState

        switch walletModelData.state {
        case .created, .loading:
            state = .loading
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
                state = .notActive
            }
        case .noAccount:
            state = .disabled
        case .failed(error: let error):
            state = .failedToLoad(error: error, cachedState: yieldModuleStateRepository.state())
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

private extension CommonYieldModuleManager {
    func hasEnterTransactions(in pendingTransactions: [PendingTransactionRecord], yieldContract: String?) -> Bool {
        let dummyDeployMethod = DeployYieldModuleMethod(
            walletAddress: String(),
            tokenContractAddress: String(),
            maxNetworkFee: .zero
        )
        let dummyInitMethod = InitYieldTokenMethod(tokenContractAddress: String(), maxNetworkFee: .zero)
        let dummyEnterMethod = EnterProtocolMethod(tokenContractAddress: String())
        let dummyReactivateMethod = ReactivateTokenMethod(tokenContractAddress: String(), maxNetworkFee: .zero)
        let dummyApproveMethod = ApproveERC20TokenMethod(spender: String(), amount: .zero)

        return hasTransactions(
            in: pendingTransactions,
            for: [
                dummyDeployMethod,
                dummyInitMethod,
                dummyReactivateMethod,
                dummyEnterMethod,
                dummyApproveMethod,
            ],
            yieldContract: yieldContract
        )
    }

    func hasExitTransactions(in pendingTransactions: [PendingTransactionRecord], yieldContract: String?) -> Bool {
        let dummyWithdrawAndDeactivateMethod = WithdrawAndDeactivateMethod(tokenContractAddress: String())
        return hasTransactions(
            in: pendingTransactions,
            for: [dummyWithdrawAndDeactivateMethod],
            yieldContract: yieldContract
        )
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
    }
}
