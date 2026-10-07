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
    /// Served from a short-lived cache unless `forceRefresh`; `nil` means there is nothing to show.
    /// A failed load is reported rather than answered with whatever the cache happens to hold — the claim
    /// is gated on this data, and a surface that may keep showing stale rewards decides that for itself.
    func incentives(forceRefresh: Bool) async throws -> YieldIncentivesRewardsSummary?
    func claimHistory(forceRefresh: Bool) async throws -> [YieldClaimHistoryEntry]?
}

extension YieldIncentivesManager {
    func incentives() async throws -> YieldIncentivesRewardsSummary? {
        try await incentives(forceRefresh: false)
    }

    func claimHistory() async throws -> [YieldClaimHistoryEntry]? {
        try await claimHistory(forceRefresh: false)
    }
}

actor CommonYieldIncentivesManager: YieldIncentivesManager {
    @Injected(\.yieldModuleNetworkManager) private var yieldModuleNetworkManager: YieldModuleNetworkManager

    private let chainId: Int
    private let userAddress: String

    private var lastFetch: (summary: YieldIncentivesRewardsSummary?, startedAt: Date)?
    private let fetchProcessor = SingleTaskProcessor<YieldIncentivesRewardsSummary?, Error>()

    private var lastHistoryFetch: (entries: [YieldClaimHistoryEntry]?, startedAt: Date)?
    private let historyFetchProcessor = SingleTaskProcessor<[YieldClaimHistoryEntry]?, Error>()

    init(chainId: Int, userAddress: String) {
        self.chainId = chainId
        self.userAddress = userAddress
    }

    func incentives(forceRefresh: Bool) async throws -> YieldIncentivesRewardsSummary? {
        // A request already in flight may have left before the event the refresh is forced for, so it runs its own.
        if forceRefresh {
            return try await fetch()
        }

        if let lastFetch, Date().timeIntervalSince(lastFetch.startedAt) < Constants.cacheWindow {
            return lastFetch.summary
        }

        return try await fetchProcessor.execute { [weak self] in
            try await self?.fetch() ?? nil
        }
    }

    func claimHistory(forceRefresh: Bool) async throws -> [YieldClaimHistoryEntry]? {
        if forceRefresh {
            return try await fetchHistory()
        }

        if let lastHistoryFetch, Date().timeIntervalSince(lastHistoryFetch.startedAt) < Constants.historyCacheWindow {
            return lastHistoryFetch.entries
        }

        return try await historyFetchProcessor.execute { [weak self] in
            try await self?.fetchHistory() ?? nil
        }
    }

    private func fetch() async throws -> YieldIncentivesRewardsSummary? {
        let startedAt = Date()
        let summary = try await yieldModuleNetworkManager.fetchIncentives(chainId: chainId, userAddress: userAddress)
        store(summary, startedAt: startedAt)

        return lastFetch?.summary
    }

    private func fetchHistory() async throws -> [YieldClaimHistoryEntry]? {
        let startedAt = Date()
        let entries = try await yieldModuleNetworkManager.fetchClaimHistory(chainId: chainId, userAddress: userAddress)
        storeHistory(entries, startedAt: startedAt)

        return lastHistoryFetch?.entries
    }

    private func store(_ summary: YieldIncentivesRewardsSummary?, startedAt: Date) {
        guard lastFetch.map({ $0.startedAt <= startedAt }) ?? true else {
            return
        }

        lastFetch = (summary, startedAt)
    }

    private func storeHistory(_ entries: [YieldClaimHistoryEntry]?, startedAt: Date) {
        guard lastHistoryFetch.map({ $0.startedAt <= startedAt }) ?? true else {
            return
        }

        lastHistoryFetch = (entries, startedAt)
    }
}

private extension CommonYieldIncentivesManager {
    enum Constants {
        static let cacheWindow: TimeInterval = 30
        static let historyCacheWindow: TimeInterval = 60
    }
}
