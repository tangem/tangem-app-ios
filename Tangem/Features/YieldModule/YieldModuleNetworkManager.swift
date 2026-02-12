//
//  YieldModuleNetworkManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import BigInt
import TangemFoundation

protocol YieldModuleNetworkManager {
    var markets: [YieldModuleMarketInfo] { get }
    var marketsPublisher: AnyPublisher<[YieldModuleMarketInfo], Never> { get }

    func updateMarkets()

    func fetchYieldTokenInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleTokenInfo
    func fetchChartData(tokenContractAddress: String, chainId: Int) async throws -> YieldChartData
    func activate(tokenContractAddress: String, walletAddress: String, chainId: Int, userWalletId: String) async throws
    func deactivate(tokenContractAddress: String, walletAddress: String, chainId: Int) async throws
    func sendTransactionEvent(txHash: String, operation: YieldModuleOperation, userAddress: String?) async
}

final class CommonYieldModuleNetworkManager {
    private let yieldModuleAPIService: YieldModuleAPIService
    private let yieldMarketsRepository: YieldModuleMarketsRepository
    private let yieldModuleChartManager: YieldModuleChartManager

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var bag = Set<AnyCancellable>()

    private let marketsSubject = CurrentValueSubject<[YieldModuleMarketInfo], Never>([])

    init(
        yieldModuleAPIService: YieldModuleAPIService,
        yieldMarketsRepository: YieldModuleMarketsRepository,
        yieldModuleChartManager: YieldModuleChartManager
    ) {
        self.yieldModuleAPIService = yieldModuleAPIService
        self.yieldMarketsRepository = yieldMarketsRepository
        self.yieldModuleChartManager = yieldModuleChartManager

        bind()
    }
}

extension CommonYieldModuleNetworkManager: YieldModuleNetworkManager {
    var markets: [YieldModuleMarketInfo] {
        marketsSubject.value
    }

    var marketsPublisher: AnyPublisher<[YieldModuleMarketInfo], Never> {
        marketsSubject.eraseToAnyPublisher()
    }

    func updateMarkets() {
        let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletRepository.models)
        let chainIDs = Set(
            walletModels.compactMap { walletModel -> String? in
                guard walletModel.tokenItem.isToken, walletModel.yieldModuleManager != nil else { return nil }
                return walletModel.tokenItem.blockchain.chainId.map { String($0) }
            }
        )

        Task { @MainActor in
            let markets = await fetchMarkets(chainIDs: Array(chainIDs))
            marketsSubject.send(markets)
        }
    }

    func fetchYieldTokenInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleTokenInfo {
        let position = try await yieldModuleAPIService.getTokenPositionInfo(
            tokenContractAddress: tokenContractAddress,
            chainId: chainId
        )

        return YieldModuleTokenInfo(
            isActive: position.isActive,
            apy: position.apy,
            maxFeeNative: position.maxFeeNative,
            maxFeeUSD: position.maxFeeUSD
        )
    }

    func fetchChartData(tokenContractAddress: String, chainId: Int) async throws -> YieldChartData {
        let chartData = try await yieldModuleAPIService.getChart(
            tokenContractAddress: tokenContractAddress,
            chainId: chainId,
            window: .lastYear,
            bucketSizeDays: nil
        )

        return YieldChartData(
            buckets: chartData.data.map { $0.avgApy.doubleValue },
            averageApy: chartData.avr,
            maxApy: chartData.data.map { $0.avgApy.doubleValue }.max() ?? 0,
            xLabels: yieldModuleChartManager.makeMonthLabels(from: chartData.from, to: chartData.to, bucketsCount: chartData.data.count)
        )
    }

    func activate(tokenContractAddress: String, walletAddress: String, chainId: Int, userWalletId: String) async throws {
        try await yieldModuleAPIService.activate(
            tokenContractAddress: tokenContractAddress,
            walletAddress: walletAddress,
            chainId: chainId,
            userWalletId: userWalletId
        )
    }

    func deactivate(tokenContractAddress: String, walletAddress: String, chainId: Int) async throws {
        try await yieldModuleAPIService.deactivate(
            tokenContractAddress: tokenContractAddress,
            walletAddress: walletAddress,
            chainId: chainId
        )
    }

    func sendTransactionEvent(txHash: String, operation: YieldModuleOperation, userAddress: String?) async {
        try? await yieldModuleAPIService.sendTransactionEvent(txHash: txHash, operation: operation.rawValue, userAddress: userAddress)
    }
}

private extension CommonYieldModuleNetworkManager {
    func bind() {
        // Observe all user wallet models, starting with current state
        let initialModelsPublisher = Deferred { [weak self] in
            Just(self?.userWalletRepository.models ?? [])
        }

        let eventModelsPublisher = userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .map { manager, _ in
                manager.userWalletRepository.models
            }

        let allUserWalletModelsPublisher = initialModelsPublisher
            .merge(with: eventModelsPublisher)
            .eraseToAnyPublisher()

        // Observe token changes across all wallets / accounts
        let allWalletModelsPublisher = allUserWalletModelsPublisher
            .map { userWalletModels in
                userWalletModels.map { userWalletModel in
                    AccountsFeatureAwareWalletModelsResolver.walletModelsPublisher(for: userWalletModel)
                }
            }
            .flatMapLatest { publishers -> AnyPublisher<[any WalletModel], Never> in
                guard !publishers.isEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                return publishers.combineLatest()
                    .map { $0.flatMap { $0 } }
                    .eraseToAnyPublisher()
            }

        // Detect EVM blockchain additions
        allWalletModelsPublisher
            .pairwise()
            .receiveOnMain()
            .sink { [weak self] value in
                guard let self else { return }

                let oldTokenItems = Set(value.0.map(\.tokenItem))
                let newTokenItems = Set(value.1.map(\.tokenItem))

                let diff = newTokenItems.subtracting(oldTokenItems)

                let didAddEVMBlockchain = diff.contains(where: { $0.isBlockchain && $0.blockchain.isEvm })

                if didAddEVMBlockchain {
                    updateMarkets()
                }
            }
            .store(in: &bag)
    }

    func fetchMarkets(chainIDs: [String]) async -> [YieldModuleMarketInfo] {
        do {
            let response = try await yieldModuleAPIService.getYieldMarkets(chainIDs: chainIDs)

            cacheMarkets(response)

            return response.tokens.compactMap {
                return YieldModuleMarketInfo(
                    tokenContractAddress: $0.tokenAddress,
                    apy: $0.apy / 100,
                    isActive: $0.isActive,
                    chainId: $0.chainId,
                    maxFeeNative: $0.maxFeeNative,
                    maxFeeUSD: $0.maxFeeUSD
                )
            }
        } catch {
            guard let cachedMarkets = yieldMarketsRepository.markets() else {
                return []
            }

            return cachedMarkets.markets.compactMap {
                return YieldModuleMarketInfo(
                    tokenContractAddress: $0.tokenContractAddress,
                    apy: $0.apy / 100,
                    isActive: $0.isActive,
                    chainId: $0.chainId,
                    maxFeeNative: $0.maxFeeNative,
                    maxFeeUSD: $0.maxFeeUSD
                )
            }
        }
    }

    func cacheMarkets(_ response: YieldModuleDTO.Response.MarketsInfo) {
        let marketsToStore = response.tokens.map {
            CachedYieldModuleMarket(
                tokenContractAddress: $0.tokenAddress,
                apy: $0.apy,
                isActive: $0.isActive,
                chainId: $0.chainId,
                maxFeeNative: $0.maxFeeNative,
                maxFeeUSD: $0.maxFeeUSD
            )
        }
        yieldMarketsRepository.store(
            markets: CachedYieldModuleMarkets(markets: marketsToStore, lastUpdated: response.lastUpdatedAt)
        )
    }
}

private struct YieldModuleNetworkManagerKey: InjectionKey {
    static var currentValue: YieldModuleNetworkManager = {
        let apiType: YieldModuleAPIType = AppEnvironment.current.isProduction
            ? .prod
            : FeatureStorage.instance.yieldModuleAPIType

        let tangemApiType: TangemAPIType = AppEnvironment.current.isProduction
            ? .prod
            : FeatureStorage.instance.tangemAPIType

        let manager = CommonYieldModuleNetworkManager(
            yieldModuleAPIService: CommonYieldModuleAPIService(
                provider: .init(
                    configuration: .ephemeralConfiguration,
                    additionalPlugins: [
                        YieldModuleAuthorizationPlugin(),
                    ]
                ),
                yieldModuleAPIType: apiType,
                tangemAPIType: tangemApiType
            ),
            yieldMarketsRepository: CommonYieldModuleMarketsRepository(),
            yieldModuleChartManager: CommonYieldModuleChartManager()
        )
        return manager
    }()
}

extension InjectedValues {
    var yieldModuleNetworkManager: YieldModuleNetworkManager {
        get { Self[YieldModuleNetworkManagerKey.self] }
        set { Self[YieldModuleNetworkManagerKey.self] = newValue }
    }
}

enum YieldModuleOperation: String {
    case enter = "YIELD_DEPOSIT"
    case exit = "YIELD_WITHDRAW"
    case send = "YIELD_SEND"
}
