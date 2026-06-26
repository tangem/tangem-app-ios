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
        // Coalesce the concurrent per-wallet calls of one bulk refresh into a single in-flight request.
        // No longer-lived cache: every fresh request re-reads the current address set, so adding or
        // removing an account reloads correctly on the next update without extra invalidation logic.
        if let inFlight {
            return try await inFlight.value
        }

        let task = Task { try await self.fetchAll() }
        inFlight = task

        do {
            let balances = try await task.value
            inFlight = nil
            return balances
        } catch {
            inFlight = nil
            throw error
        }
    }

    private func fetchAll() async throws -> [String: [StakingBalanceInfo]] {
        let yield = try await yieldInfoProvider.yieldInfo(for: StakingIntegrationId.ethereumP2P.rawValue)
        let vaults = yield.targets.map(\.address)

        // Deduplicate case-insensitively while keeping a concrete casing for the request.
        let addresses = Array(
            Dictionary(addressProvider.delegatorAddresses().map { ($0.lowercased(), $0) }, uniquingKeysWith: { first, _ in first })
                .values
        )

        guard !vaults.isEmpty, !addresses.isEmpty else {
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
