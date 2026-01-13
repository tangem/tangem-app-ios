//
//  StakingYieldInfoProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingYieldInfoProvider {
    func yieldInfo(for integrationId: String) async throws -> StakingYieldInfo
}

public final actor CommonStakingYieldInfoProvider {
    private let stakeKitAPIProvider: StakeKitAPIProvider
    private let p2pAPIProvider: P2PAPIProvider

    private var yieldInfos = [String: CachedStakingYieldInfo]()
    private var loadingTasks = [String: Task<StakingYieldInfo, Error>]()

    public init(stakeKitAPIProvider: StakeKitAPIProvider, p2pAPIProvider: P2PAPIProvider) {
        self.stakeKitAPIProvider = stakeKitAPIProvider
        self.p2pAPIProvider = p2pAPIProvider
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
        let task = Task<StakingYieldInfo, Error> {
            switch integrationId {
            case StakingIntegrationId.ethereumP2P.rawValue:
                try await p2pAPIProvider.yield()
            default:
                try await stakeKitAPIProvider.yield(integrationId: integrationId)
            }
        }

        loadingTasks[integrationId] = task

        do {
            let result = try await task.value
            // Store in cache after successful load
            yieldInfos[integrationId] = CachedStakingYieldInfo(
                stakingYieldInfo: result,
                timestamp: Date()
            )
            loadingTasks[integrationId] = nil
            return result
        } catch {
            // Clean up failed task
            loadingTasks[integrationId] = nil
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
