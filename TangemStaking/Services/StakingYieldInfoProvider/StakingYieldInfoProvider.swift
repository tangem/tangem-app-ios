//
//  StakingYieldInfoProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol StakingYieldInfoProvider {
    func yieldInfo(for integrationId: String) async throws -> StakingYieldInfo
}

public final actor CommonStakingYieldInfoProvider {
    private let stakeKitAPIProvider: StakeKitAPIProvider
    private let p2pAPIProvider: P2PAPIProvider
    private let targetAmountLimitProvider: StakingTargetAmountLimitProvider?

    private var yieldInfos = [String: CachedStakingYieldInfo]()
    private var loadingTasks = [String: Task<StakingYieldInfo, Error>]()
    private var bag: Set<AnyCancellable> = []

    public init(
        stakeKitAPIProvider: StakeKitAPIProvider,
        p2pAPIProvider: P2PAPIProvider,
        targetAmountLimitProvider: StakingTargetAmountLimitProvider? = nil,
        cacheInvalidationPublisher: AnyPublisher<Void, Never>? = nil
    ) {
        self.stakeKitAPIProvider = stakeKitAPIProvider
        self.p2pAPIProvider = p2pAPIProvider
        self.targetAmountLimitProvider = targetAmountLimitProvider

        if let cacheInvalidationPublisher {
            Task { [weak self] in
                await self?.bind(cacheInvalidationPublisher: cacheInvalidationPublisher)
            }
        }
    }

    private func bind(cacheInvalidationPublisher: AnyPublisher<Void, Never>) {
        cacheInvalidationPublisher
            .sink { [weak self] in
                Task { await self?.invalidateCache() }
            }
            .store(in: &bag)
    }

    func invalidateCache() {
        loadingTasks.values.forEach { $0.cancel() }
        loadingTasks.removeAll()
        yieldInfos.removeAll()
    }
}

extension CommonStakingYieldInfoProvider: StakingYieldInfoProvider {
    public func yieldInfo(for integrationId: String) async throws -> StakingYieldInfo {
        // Check cache
        if let cached = yieldInfos[integrationId], !cached.isExpired {
            return cached.stakingYieldInfo
        }

        // Check if already loading
        if let task = loadingTasks[integrationId] {
            return try await task.value
        }

        // Create new loading task
        let task = Task<StakingYieldInfo, Error> { [weak self] in
            guard let self else { throw CancellationError() }
            switch integrationId {
            case StakingIntegrationId.ethereumP2P.rawValue:
                return try await p2pAPIProvider.yield(targetAmountLimitProvider: targetAmountLimitProvider)
            default:
                return try await stakeKitAPIProvider.yield(integrationId: integrationId)
            }
        }

        loadingTasks[integrationId] = task

        do {
            let result = try await task.value
            guard loadingTasks[integrationId] == task else {
                return result
            }
            yieldInfos[integrationId] = CachedStakingYieldInfo(
                stakingYieldInfo: result,
                timestamp: Date()
            )
            loadingTasks[integrationId] = nil
            return result
        } catch {
            if loadingTasks[integrationId] == task {
                loadingTasks[integrationId] = nil
            }
            throw error
        }
    }
}

private struct CachedStakingYieldInfo {
    let stakingYieldInfo: StakingYieldInfo
    let timestamp: Date

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > Constants.cacheValidityInterval
    }
}

private extension CachedStakingYieldInfo {
    enum Constants {
        static let cacheValidityInterval: TimeInterval = 180 // 3 minutes
    }
}
