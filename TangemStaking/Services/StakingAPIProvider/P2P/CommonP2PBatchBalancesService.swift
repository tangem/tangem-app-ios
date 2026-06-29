//
//  CommonP2PBatchBalancesService.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

actor CommonP2PBatchBalancesService: P2PBatchBalancesService {
    private let service: P2PStakingAPIService
    private let mapper: P2PMapper
    private let addressProvider: P2PDelegatorAddressProvider
    private let yieldInfoProvider: StakingYieldInfoProvider
    private let debounceInterval: TimeInterval

    private var inFlight: InFlight?
    private var cached: Cached?
    private var generation = 0
    private var subscription: AnyCancellable?

    init(
        service: P2PStakingAPIService,
        mapper: P2PMapper,
        addressProvider: P2PDelegatorAddressProvider,
        yieldInfoProvider: StakingYieldInfoProvider,
        debounceInterval: TimeInterval = Constants.defaultDebounceInterval
    ) {
        self.service = service
        self.mapper = mapper
        self.addressProvider = addressProvider
        self.yieldInfoProvider = yieldInfoProvider
        self.debounceInterval = debounceInterval

        Task { await observeAddressChanges() }
    }

    func balances() async throws -> [String: [StakingBalanceInfo]] {
        try await fetch(for: addressProvider.delegatorAddresses(), forceRefresh: false)
    }

    // MARK: - Publisher-driven proactive refresh

    private func observeAddressChanges() {
        subscription = addressProvider
            .delegatorAddressesPublisher
            .map { Set($0) }
            .removeDuplicates()
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.global(qos: .utility))
            .sink { [weak self] addresses in
                Task { [weak self] in
                    try? await self?.fetch(for: Array(addresses), forceRefresh: true)
                }
            }
    }

    // MARK: - Core

    @discardableResult
    private func fetch(for addresses: [String], forceRefresh: Bool) async throws -> [String: [StakingBalanceInfo]] {
        let requested = dedupedPreservingCase(addresses)
        let key = Set(requested.map { $0.lowercased() })

        if let inFlight, inFlight.key.isSuperset(of: key) {
            return try await inFlight.task.value
        }

        if !forceRefresh, let cached, !cached.isExpired, cached.key.isSuperset(of: key) {
            return cached.balances
        }

        generation += 1
        let id = generation
        let task = Task { try await self.fetchAll(delegatorAddresses: requested) }
        inFlight = InFlight(id: id, key: key, task: task)

        do {
            let balances = try await task.value
            cached = Cached(key: key, balances: balances, timestamp: Date())
            clearInFlight(id: id)
            return balances
        } catch {
            clearInFlight(id: id)
            throw error
        }
    }

    private func clearInFlight(id: Int) {
        if inFlight?.id == id {
            inFlight = nil
        }
    }

    private func dedupedPreservingCase(_ addresses: [String]) -> [String] {
        var seen = Set<String>()
        var result = [String]()
        for address in addresses where seen.insert(address.lowercased()).inserted {
            result.append(address)
        }
        return result
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
    struct InFlight {
        let id: Int
        let key: Set<String>
        let task: Task<[String: [StakingBalanceInfo]], Error>
    }

    struct Cached {
        let key: Set<String>
        let balances: [String: [StakingBalanceInfo]]
        let timestamp: Date

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > Constants.cacheValidityInterval
        }
    }

    enum Constants {
        static let defaultDebounceInterval: TimeInterval = 1
        static let cacheValidityInterval: TimeInterval = 60
    }
}
