//
//  CommonP2PBatchBalancesService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

actor CommonP2PBatchBalancesService: P2PBatchBalancesService {
    private let service: P2PStakingAPIService
    private let mapper: P2PMapper
    private let addressProvider: P2PDelegatorAddressProvider
    private let yieldInfoProvider: StakingYieldInfoProvider

    private var inFlight: Task<[String: [StakingBalanceInfo]], Error>?
    private var cached: Cached?

    init(
        service: P2PStakingAPIService,
        mapper: P2PMapper,
        addressProvider: P2PDelegatorAddressProvider,
        yieldInfoProvider: StakingYieldInfoProvider
    ) {
        self.service = service
        self.mapper = mapper
        self.addressProvider = addressProvider
        self.yieldInfoProvider = yieldInfoProvider
    }

    func balances() async throws -> [String: [StakingBalanceInfo]] {
        // Per-wallet managers pull at spread-out times during one refresh, so a short cache keyed by the
        // delegator-address set collapses them into a single POST. The key is the address set itself, so
        // adding/removing an account changes the key and forces an immediate refetch (no stale data), while
        // concurrent pulls additionally share the in-flight task.
        let addressMap = Dictionary(
            addressProvider.delegatorAddresses().map { ($0.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let addressKey = Set(addressMap.keys)

        if let cached, cached.addressKey == addressKey, !cached.isExpired {
            return cached.balances
        }

        if let inFlight {
            return try await inFlight.value
        }

        let addresses = Array(addressMap.values)
        let task = Task { try await self.fetchAll(delegatorAddresses: addresses) }
        inFlight = task

        do {
            let balances = try await task.value
            cached = Cached(addressKey: addressKey, balances: balances, timestamp: Date())
            inFlight = nil
            return balances
        } catch {
            inFlight = nil
            throw error
        }
    }

    private func fetchAll(delegatorAddresses addresses: [String]) async throws -> [String: [StakingBalanceInfo]] {
        guard !addresses.isEmpty else {
            return [:]
        }

        let yield = try await yieldInfoProvider.yieldInfo(for: StakingIntegrationId.ethereumP2P.rawValue)
        let vaults = yield.targets.map(\.address)

        guard !vaults.isEmpty else {
            return [:]
        }

        let infos = try await withThrowingTaskGroup(of: P2PDTO.AccountsList.AccountsListInfo.self) { [service] group in
            for vault in vaults {
                group.addTask {
                    try await service.getAccountsList(vaultAddress: vault, delegatorAddresses: addresses)
                }
            }

            var collected = [P2PDTO.AccountsList.AccountsListInfo]()
            for try await info in group {
                collected.append(info)
            }
            return collected
        }

        var result = [String: [StakingBalanceInfo]]()
        for info in infos {
            for item in info.list {
                guard let account = item.account else { continue }
                result[item.delegatorAddress.lowercased(), default: []].append(contentsOf: mapper.mapToBalancesInfo(from: account))
            }
        }

        return result
    }
}

private extension CommonP2PBatchBalancesService {
    struct Cached {
        let addressKey: Set<String>
        let balances: [String: [StakingBalanceInfo]]
        let timestamp: Date

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > Constants.cacheValidityInterval
        }
    }

    enum Constants {
        /// Long enough to coalesce a single refresh cycle's spread-out per-wallet pulls; staking balances
        /// change slowly, so serving a slightly older value within this window is acceptable.
        static let cacheValidityInterval: TimeInterval = 60
    }
}
