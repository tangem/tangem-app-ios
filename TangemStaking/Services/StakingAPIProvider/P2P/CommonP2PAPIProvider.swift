//
//  CommonP2PAPIProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class CommonP2PAPIProvider: P2PAPIProvider {
    let service: P2PStakingAPIService
    let mapper: P2PMapper

    init(service: P2PStakingAPIService, mapper: P2PMapper) {
        self.service = service
        self.mapper = mapper
    }

    func yield() async throws -> StakingYieldInfo {
        let response = try await service.getVaultsList()
        return try mapper.mapToYieldInfo(from: response)
    }

    func balances(wallet: StakingWallet, vaults: [String]) async throws -> [StakingBalanceInfo] {
        try await withThrowingTaskGroup(of: StakingBalanceInfo?.self) { [service, mapper] group in
            var results = [StakingBalanceInfo?]()

            vaults.forEach { vault in
                group.addTask {
                    let response = try await service.getAccountSummary(
                        delegatorAddress: wallet.address,
                        vaultAddress: vault
                    )
                    return try mapper.mapToBalanceInfo(from: response)
                }
            }

            for try await result in group {
                results.append(result)
            }

            return results.compactMap { $0 }
        }
    }
}
