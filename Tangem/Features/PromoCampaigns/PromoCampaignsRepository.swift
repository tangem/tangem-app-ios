//
//  PromoCampaignsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemNetworkUtils
import class Alamofire.RetryPolicy

protocol PromoCampaignsProviding {
    func initialize()
    func campaignsPublisher(for userWalletId: UserWalletId) -> AnyPublisher<[PromoCampaign], Never>
}

final class PromoCampaignsRepository {
    private let walletsProvider: PromoCampaignWalletsProviding
    private let campaignsLoader: PromoCampaignsLoading
    private let isEnabled: () -> Bool
    private let retryCount: Int
    private let retryInterval: (_ retryAttempt: Int) -> UInt64
    private let campaignsSubject = CurrentValueSubject<[UserWalletId: [PromoCampaign]], Never>([:])
    private let requestedWallets = OSAllocatedUnfairLock(initialState: RequestedWallets())
    private var walletsSubscription: AnyCancellable?

    init(
        walletsProvider: PromoCampaignWalletsProviding = CommonPromoCampaignWalletsProvider(),
        campaignsLoader: PromoCampaignsLoading = CommonPromoCampaignsLoader(),
        isEnabled: @escaping () -> Bool = { PromoCampaignsAvailability.isEnabled },
        retryCount: Int = Constants.retryCount,
        retryInterval: @escaping (_ retryAttempt: Int) -> UInt64 = { ExponentialBackoffInterval(retryAttempt: $0)() }
    ) {
        self.walletsProvider = walletsProvider
        self.campaignsLoader = campaignsLoader
        self.isEnabled = isEnabled
        self.retryCount = retryCount
        self.retryInterval = retryInterval
    }
}

// MARK: - PromoCampaignsProviding

extension PromoCampaignsRepository: PromoCampaignsProviding {
    func initialize() {
        guard isEnabled(), walletsSubscription == nil else {
            return
        }

        walletsSubscription = walletsProvider.walletsPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { repository, wallets in
                repository.forgetRemovedWallets(keeping: wallets)
                repository.loadCampaigns(forNewWalletsAmong: wallets)
            }
    }

    func campaignsPublisher(for userWalletId: UserWalletId) -> AnyPublisher<[PromoCampaign], Never> {
        campaignsSubject
            .map { $0[userWalletId] ?? [] }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension PromoCampaignsRepository {
    func forgetRemovedWallets(keeping wallets: [PromoCampaignWallet]) {
        let loadedWalletIds = requestedWallets.withLock { $0.keepOnly(wallets) }
        let campaigns = campaignsSubject.value.filter { loadedWalletIds.contains($0.key) }

        if campaigns.count != campaignsSubject.value.count {
            campaignsSubject.value = campaigns
        }
    }

    func loadCampaigns(forNewWalletsAmong wallets: [PromoCampaignWallet]) {
        let loads = requestedWallets.withLock { $0.startLoading(newWalletsAmong: wallets) }

        guard loads.isNotEmpty else {
            return
        }

        runTask(in: self) { repository in
            await withTaskGroup(of: LoadResult.self) { group in
                for load in loads {
                    group.addTask {
                        let campaigns = await repository.loadCampaigns(for: load.wallet)
                        return LoadResult(load: load, campaigns: campaigns)
                    }
                }

                for await result in group {
                    await repository.apply(result)
                }
            }
        }
    }

    func loadCampaigns(for wallet: PromoCampaignWallet) async -> [PromoCampaign]? {
        do {
            return try await retry { try await campaignsLoader.loadPromoCampaigns(for: wallet) }
        } catch {
            if !error.isCancellationError {
                PromotionsLogger.error("Loading promo campaigns for wallet \(wallet.userWalletId.stringValue.masked())", error: error)
            }

            return nil
        }
    }

    func retry<T>(work: () async throws -> T) async throws -> T {
        var currentRetryAttempt = 0

        while true {
            do {
                if currentRetryAttempt > 0 {
                    try await Task.sleep(nanoseconds: retryInterval(currentRetryAttempt))
                }

                return try await work()
            } catch where currentRetryAttempt < retryCount && Self.isRetryable(error) {
                currentRetryAttempt += 1
            }
        }
    }

    static func isRetryable(_ error: Error) -> Bool {
        if let statusCode = error.asMoyaError?.response?.statusCode, !(200 ... 299).contains(statusCode) {
            return (500 ... 599).contains(statusCode)
        }

        if let networkErrorCode = error.asMoyaError?.underlyingError?.asAFError?.networkErrorCode ?? error.networkErrorCode {
            return RetryPolicy.defaultRetryableURLErrorCodes.contains(networkErrorCode)
        }

        return false
    }

    @MainActor
    func apply(_ result: LoadResult) {
        let isCurrentLoad = requestedWallets.withLock { $0.finishLoading(result.load, isLoaded: result.campaigns != nil) }

        guard isCurrentLoad, let campaigns = result.campaigns else {
            return
        }

        campaignsSubject.value[result.load.wallet.userWalletId] = campaigns
    }
}

// MARK: - Auxiliary types

private extension PromoCampaignsRepository {
    struct Load: Hashable {
        let id = UUID()
        let wallet: PromoCampaignWallet
    }

    struct LoadResult {
        let load: Load
        let campaigns: [PromoCampaign]?
    }

    struct RequestedWallets {
        var inFlight: [UserWalletId: Load] = [:]
        var loaded: [UserWalletId: PromoCampaignWallet] = [:]

        mutating func keepOnly(_ wallets: [PromoCampaignWallet]) -> Set<UserWalletId> {
            let currentWallets = Set(wallets)
            inFlight = inFlight.filter { currentWallets.contains($0.value.wallet) }
            loaded = loaded.filter { currentWallets.contains($0.value) }
            return Set(loaded.keys)
        }

        mutating func startLoading(newWalletsAmong wallets: [PromoCampaignWallet]) -> [Load] {
            let loads = wallets
                .filter { inFlight[$0.userWalletId] == nil && loaded[$0.userWalletId] == nil }
                .map { Load(wallet: $0) }

            loads.forEach { inFlight[$0.wallet.userWalletId] = $0 }
            return loads
        }

        mutating func finishLoading(_ load: Load, isLoaded: Bool) -> Bool {
            let userWalletId = load.wallet.userWalletId

            guard inFlight[userWalletId] == load else {
                return false
            }

            inFlight[userWalletId] = nil

            if isLoaded {
                loaded[userWalletId] = load.wallet
            }

            return true
        }
    }
}

// MARK: - Constants

private extension PromoCampaignsRepository {
    enum Constants {
        static let retryCount = 3
    }
}

// MARK: - DI

private struct PromoCampaignsRepositoryKey: InjectionKey {
    static var currentValue: PromoCampaignsProviding = PromoCampaignsRepository()
}

extension InjectedValues {
    var promoCampaignsRepository: PromoCampaignsProviding {
        get { Self[PromoCampaignsRepositoryKey.self] }
        set { Self[PromoCampaignsRepositoryKey.self] = newValue }
    }
}
