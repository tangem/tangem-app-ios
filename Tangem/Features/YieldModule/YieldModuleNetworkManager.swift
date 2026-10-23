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
import TangemNetworkUtils

protocol YieldModuleNetworkManager {
    var markets: [YieldModuleMarketInfo] { get }
    var marketsPublisher: AnyPublisher<[YieldModuleMarketInfo], Never> { get }

    func updateMarkets()

    func fetchYieldTokenInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleTokenInfo
    func fetchChartData(tokenContractAddress: String, chainId: Int) async throws -> YieldChartData
    func fetchAprHistory(tokenContractAddress: String, chainId: Int, days: Int) async throws -> [YieldIncentiveAprPoint]
    func fetchIncentives(chainId: Int, userAddress: String) async throws -> YieldIncentivesRewardsSummary?
    func fetchClaimCalldata(chainId: Int, userAddress: String) async throws -> YieldClaimCalldata
    func fetchClaimHistory(chainId: Int, userAddress: String) async throws -> [YieldClaimHistoryEntry]?
    func activate(tokenContractAddress: String, walletAddress: String, chainId: Int, userWalletId: String) async throws
    func deactivate(tokenContractAddress: String, walletAddress: String, chainId: Int) async throws
    func sendTransactionEvent(txHash: String, operation: YieldModuleOperation, userAddress: String?) async
}

final class CommonYieldModuleNetworkManager {
    private let yieldModuleAPIService: YieldModuleAPIService
    private let yieldMarketsRepository: YieldModuleMarketsRepository
    private let yieldModuleChartManager: YieldModuleChartManager
    private let blockchainAvailability: YieldModuleBlockchainAvailability

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private var bag = Set<AnyCancellable>()

    private let marketsSubject = CurrentValueSubject<[YieldModuleMarketInfo], Never>([])

    private let inFlightMarketsUpdate = OSAllocatedUnfairLock<UUID?>(initialState: nil)

    init(
        yieldModuleAPIService: YieldModuleAPIService,
        yieldMarketsRepository: YieldModuleMarketsRepository,
        yieldModuleChartManager: YieldModuleChartManager,
        blockchainAvailability: YieldModuleBlockchainAvailability = YieldModuleBlockchainAvailability()
    ) {
        self.yieldModuleAPIService = yieldModuleAPIService
        self.yieldMarketsRepository = yieldMarketsRepository
        self.yieldModuleChartManager = yieldModuleChartManager
        self.blockchainAvailability = blockchainAvailability

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

    /// Every call derives the same chain IDs from all user wallets, so the newest one subsumes the ones before it.
    func updateMarkets() {
        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletRepository.models)
        let chainIDs = Set(
            walletModels.compactMap { walletModel -> String? in
                guard walletModel.tokenItem.isToken, walletModel.yieldModuleManager != nil else { return nil }
                return walletModel.tokenItem.blockchain.chainId.map { String($0) }
            }
        )

        let token = UUID()
        inFlightMarketsUpdate { $0 = token }

        Task { @MainActor [weak self] in
            guard let self else { return }

            let (markets, freshResponse) = await fetchMarkets(chainIDs: Array(chainIDs))

            // A newer request has been claimed since this one started, so its response is stale.
            let isLatestRequest = inFlightMarketsUpdate { inFlightToken -> Bool in
                guard inFlightToken == token else {
                    return false
                }

                inFlightToken = nil

                return true
            }

            guard isLatestRequest else {
                return
            }

            if let freshResponse {
                cacheMarkets(freshResponse)
            }

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

    func fetchAprHistory(tokenContractAddress: String, chainId: Int, days: Int) async throws -> [YieldIncentiveAprPoint] {
        let history = try await yieldModuleAPIService.getAprHistory(
            chainId: chainId,
            tokenAddress: tokenContractAddress,
            days: days
        )

        // Points arrive in ascending date order and are plotted as is; unparseable dates are dropped.
        return history.points.compactMap { point in
            Self.aprHistoryDateFormatter.date(from: point.date).map {
                YieldIncentiveAprPoint(
                    date: $0,
                    baseApy: point.baseApy / 100,
                    grossTotalApyEst: point.grossTotalApyEst / 100
                )
            }
        }
    }

    func fetchIncentives(chainId: Int, userAddress: String) async throws -> YieldIncentivesRewardsSummary? {
        let incentives = try await yieldModuleAPIService.getIncentives(chainId: chainId, userAddress: userAddress)

        return incentives.flatMap(YieldIncentivesRewardsSummary.init(dto:))
    }

    func fetchClaimCalldata(chainId: Int, userAddress: String) async throws -> YieldClaimCalldata {
        let calldata = try await yieldModuleAPIService.getClaimCalldata(chainId: chainId, userAddress: userAddress)

        return YieldClaimCalldata(dto: calldata)
    }

    func fetchClaimHistory(chainId: Int, userAddress: String) async throws -> [YieldClaimHistoryEntry]? {
        let history = try await yieldModuleAPIService.getClaimHistory(chainId: chainId, userAddress: userAddress)

        return history?.claims.map(YieldClaimHistoryEntry.init(dto:))
    }

    private static let aprHistoryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

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
                    AccountWalletModelsAggregator.walletModelsPublisher(from: userWalletModel.accountModelsManager)
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

    /// Caching is left to the caller so that a superseded response cannot overwrite the cache after the newest one.
    func fetchMarkets(
        chainIDs: [String]
    ) async -> (markets: [YieldModuleMarketInfo], freshResponse: YieldModuleDTO.Response.MarketsInfo?) {
        let includeIncentive = FeatureProvider.isAvailable(.merklIncentives)

        do {
            let response = includeIncentive
                ? try await yieldModuleAPIService.getIncentiveYieldMarkets(chainIDs: chainIDs)
                : try await yieldModuleAPIService.getYieldMarkets(chainIDs: chainIDs)

            let markets = response.tokens
                .map { YieldModuleMarketInfo(dto: $0, includeIncentive: includeIncentive) }
                .filter { blockchainAvailability.isAvailable(chainId: $0.chainId) }

            return (markets, response)
        } catch {
            AppLogger.error("Failed to load yield markets. Falling back to the cached markets.", error: error)

            guard let cachedMarkets = yieldMarketsRepository.markets() else {
                return ([], nil)
            }

            let markets = cachedMarkets.markets
                .map(YieldModuleMarketInfo.init(from:))
                .filter { blockchainAvailability.isAvailable(chainId: $0.chainId) }

            return (markets, nil)
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
                        DeviceInfoPlugin(),
                        YieldModuleAuthorizationPlugin(),
                        CachePolicyPlugin(),
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
