//
//  P2PMapper.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct P2PMapper {
    func mapToYieldInfo(from response: P2PDTO.Vaults.VaultsInfo) throws -> StakingYieldInfo {
        let item: StakingTokenItem = .ethereum
        let rewardType: RewardType = .apy
        let validators = response.vaults.map { mapToValidatorInfo(from: $0) }

        let rewardRateValues = RewardRateValues(
            aprs: validators.compactMap(\.rewardRate),
            rewardRate: .zero
        )

        return StakingYieldInfo(
            id: "ethereum",
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
            item: .ethereum,
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

extension StakingTokenItem {
    static var ethereum: StakingTokenItem {
        return StakingTokenItem(
            network: "ethereum",
            name: "Ethereum",
            decimals: 18,
            symbol: "ETH"
        )
    }
}
