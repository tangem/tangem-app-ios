//
//  P2PMapper.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct P2PMapper {
    let item: StakingTokenItem = .ethereum
    let rewardType: RewardType = .apy

    func mapToYieldInfo(from response: P2PDTO.Vaults.VaultsInfo) throws -> StakingYieldInfo {
        let validators = response.vaults.map { mapToValidatorInfo(from: $0) }

        let rewardRateValues = RewardRateValues(
            aprs: validators.compactMap(\.rewardRate),
            rewardRate: .zero
        )

        return StakingYieldInfo(
            id: item.network.rawValue,
            isAvailable: true,
            rewardType: rewardType,
            rewardRateValues: rewardRateValues,
            enterMinimumRequirement: .zero,
            exitMinimumRequirement: .zero,
            validators: validators,
            preferredValidators: [],
            item: item,
            unbondingPeriod: .interval(minDays: 1, maxDays: 4),
            warmupPeriod: .specific(days: 0),
            rewardClaimingType: .manual,
            rewardScheduleType: .daily
        )
    }

    func mapToBalanceInfo(from response: P2PDTO.AccountSummary.AccountSummaryInfo) throws -> StakingBalanceInfo? {
        guard let assets = response.stake.assets, assets > .zero else {
            return nil
        }
        return StakingBalanceInfo(
            item: item,
            amount: assets,
            balanceType: .active,
            validatorAddress: response.vaultAddress,
            actions: []
        )
    }

    func mapToValidatorInfo(from vault: P2PDTO.Vaults.Vault) -> ValidatorInfo {
        ValidatorInfo(
            address: vault.vaultAddress,
            name: vault.displayName,
            preferred: false,
            partner: false,
            iconURL: nil,
            rewardType: .apy,
            rewardRate: vault.apy ?? .zero,
            status: .active
        )
    }
}

public extension StakingTokenItem {
    static var ethereum: StakingTokenItem {
        let blockchain: Blockchain = .ethereum(testnet: false)
        return StakingTokenItem(
            network: .ethereum,
            name: blockchain.displayName,
            decimals: blockchain.decimalCount,
            symbol: blockchain.currencySymbol
        )
    }
}
