//
//  LendingRateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import TangemFoundation

protocol LendingRateProvider {
    func currentApy() async throws -> Decimal
}

struct CommonLendingRateProvider: LendingRateProvider {
    @Injected(\.yieldModuleNetworkManager) private var networkManager: YieldModuleNetworkManager

    func currentApy() async throws -> Decimal {
        guard let chainId = LendingOnAave.blockchain.chainId else {
            throw YieldModuleError.unsupportedBlockchain
        }

        let info = try await networkManager.fetchYieldTokenInfo(
            tokenContractAddress: LendingOnAave.wrappedNativeAddress,
            chainId: chainId
        )

        return info.apy
    }
}

protocol LendingRateRepository: AnyObject {
    var apy: Decimal? { get }
    var apyPublisher: AnyPublisher<Decimal?, Never> { get }

    func loadApyIfNeeded()
    func refreshApy() async throws -> Decimal
}

final class CommonLendingRateRepository: LendingRateRepository {
    private let provider: LendingRateProvider
    private let apySubject = CurrentValueSubject<Decimal?, Never>(nil)
    private let isLoading = OSAllocatedUnfairLock(initialState: false)
    private let requests = OSAllocatedUnfairLock(initialState: (issued: 0, published: 0))

    init(provider: LendingRateProvider) {
        self.provider = provider
    }

    var apy: Decimal? {
        apySubject.value
    }

    var apyPublisher: AnyPublisher<Decimal?, Never> {
        apySubject.removeDuplicates().eraseToAnyPublisher()
    }

    func loadApyIfNeeded() {
        let shouldLoad = isLoading.withLock { isLoading in
            guard Self.shouldLoad(isLoading: isLoading, hasApy: apySubject.value != nil) else {
                return false
            }

            isLoading = true
            return true
        }

        guard shouldLoad else {
            return
        }

        Task { [weak self] in
            do {
                _ = try await self?.refreshApy()
            } catch {
                AppLogger.error(error: error)
            }

            self?.isLoading.withLock { $0 = false }
        }
    }

    func refreshApy() async throws -> Decimal {
        let request = requests.withLock { requests in
            requests.issued += 1
            return requests.issued
        }

        let apy = try await provider.currentApy()

        requests.withLock { requests in
            guard request > requests.published else {
                return
            }

            requests.published = request
            apySubject.send(apy)
        }

        return apy
    }

    static func shouldLoad(isLoading: Bool, hasApy: Bool) -> Bool {
        !isLoading && !hasApy
    }
}

// MARK: - Injection

private struct LendingRateRepositoryKey: InjectionKey {
    static var currentValue: LendingRateRepository = CommonLendingRateRepository(provider: CommonLendingRateProvider())
}

extension InjectedValues {
    var lendingRateRepository: LendingRateRepository {
        get { Self[LendingRateRepositoryKey.self] }
        set { Self[LendingRateRepositoryKey.self] = newValue }
    }
}
