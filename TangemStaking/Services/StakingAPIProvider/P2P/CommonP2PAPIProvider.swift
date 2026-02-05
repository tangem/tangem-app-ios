//
//  CommonP2PAPIProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

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

    func balances(walletAddress: String, vaults: [String]) async throws -> [StakingBalanceInfo] {
        try await withThrowingTaskGroup(of: [StakingBalanceInfo].self) { [service, mapper] group in
            var results = [StakingBalanceInfo]()

            for vault in vaults {
                group.addTask {
                    let response = try await service.getAccountSummary(
                        delegatorAddress: walletAddress,
                        vaultAddress: vault
                    )
                    return mapper.mapToBalancesInfo(from: response)
                }
            }

            for try await result in group {
                results.append(contentsOf: result)
            }

            return results.compactMap { $0 }
        }
    }

    func stakeTransaction(
        walletAddress: String,
        vault: String,
        amount: Decimal
    ) async throws -> StakingTransactionInfo {
        let response = try await service.prepareDepositTransaction(
            request: .init(delegatorAddress: walletAddress, vaultAddress: vault, amount: amount)
        )

        return try mapper.mapToStakingTransactionInfo(from: response, walletAddress: walletAddress)
    }

    func unstakeTransaction(
        walletAddress: String,
        vault: String,
        amount: Decimal
    ) async throws -> StakingTransactionInfo {
        let response = try await service.prepareUnstakeTransaction(
            request: .init(delegatorAddress: walletAddress, vaultAddress: vault, amount: amount)
        )

        return try mapper.mapToStakingTransactionInfo(from: response, walletAddress: walletAddress)
    }

    func withdrawTransaction(
        walletAddress: String,
        vault: String,
        amount: Decimal
    ) async throws -> StakingTransactionInfo {
        let response = try await service.prepareWithdrawTransaction(
            request: .init(delegatorAddress: walletAddress, vaultAddress: vault, amount: amount)
        )

        return try mapper.mapToStakingTransactionInfo(from: response, walletAddress: walletAddress)
    }

    func broadcastTransaction(signedTransaction: String) async throws -> String {
        let response = try await service.broadcastTransaction(request: .init(signedTransaction: signedTransaction))

        return response.hash
    }
}
