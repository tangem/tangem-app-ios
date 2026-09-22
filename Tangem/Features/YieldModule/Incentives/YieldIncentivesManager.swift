//
//  YieldIncentivesManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol YieldIncentivesManager: AnyObject {
    /// Never throws — incentive failures must not degrade base Yield Mode; `nil` means nothing to show.
    func incentives(forceRefresh: Bool) async -> YieldIncentivesRewardsSummary?
}

extension YieldIncentivesManager {
    func incentives() async -> YieldIncentivesRewardsSummary? {
        await incentives(forceRefresh: false)
    }
}

actor CommonYieldIncentivesManager: YieldIncentivesManager {
    @Injected(\.yieldModuleNetworkManager) private var yieldModuleNetworkManager: YieldModuleNetworkManager

    private let chainId: Int
    private let userAddress: String

    private var lastFetch: (summary: YieldIncentivesRewardsSummary?, startedAt: Date)?
    private let fetchProcessor = SingleTaskProcessor<YieldIncentivesRewardsSummary?, Never>()

    init(chainId: Int, userAddress: String) {
        self.chainId = chainId
        self.userAddress = userAddress
    }

    func incentives(forceRefresh: Bool) async -> YieldIncentivesRewardsSummary? {
        // A request already in flight may have left before the event the refresh is forced for, so it runs its own.
        if forceRefresh {
            return await fetch(startedAt: Date())
        }

        if let lastFetch, Date().timeIntervalSince(lastFetch.startedAt) < Constants.cacheWindow {
            return lastFetch.summary
        }

        return await fetchProcessor.execute { [weak self] in
            await self?.fetch(startedAt: Date()) ?? nil
        }
    }

    private func fetch(startedAt: Date) async -> YieldIncentivesRewardsSummary? {
        do {
            let summary = try await yieldModuleNetworkManager.fetchIncentives(chainId: chainId, userAddress: userAddress)
            store(summary, startedAt: startedAt)
            return summary
        } catch {
            AppLogger.error("Failed to load yield incentives", error: error)

            // Not cached, so the next call retries; the previous data keeps an open surface from going empty.
            return lastFetch?.summary
        }
    }

    private func store(_ summary: YieldIncentivesRewardsSummary?, startedAt: Date) {
        guard lastFetch.map({ $0.startedAt <= startedAt }) ?? true else {
            return
        }

        lastFetch = (summary, startedAt)
    }
}

private extension CommonYieldIncentivesManager {
    enum Constants {
        static let cacheWindow: TimeInterval = 30
    }
}
