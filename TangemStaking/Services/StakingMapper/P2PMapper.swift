//
//  P2PMapper.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

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
            enterMinimumRequirement: StakingConstants.p2pEnterMinimumRequirements,
            exitMinimumRequirement: .zero,
            validators: validators,
            preferredValidators: validators,
            item: item,
            unbondingPeriod: .variable(minDays: 1, maxDays: 4),
            warmupPeriod: .constant(days: 0),
            rewardClaimingType: .auto,
            rewardScheduleType: .daily
        )
    }

    func mapToBalancesInfo(from response: P2PDTO.AccountSummary.AccountSummaryInfo) -> [StakingBalanceInfo] {
        var balances = [StakingBalanceInfo]()
        if let assets = response.stake.assets, assets > .zero {
            balances.append(
                StakingBalanceInfo(
                    item: .ethereum,
                    amount: assets,
                    balanceType: .active,
                    validatorAddress: response.vaultAddress,
                    actions: []
                ),
            )
        }

        let unstakingBalances = response.exitQueue.requests.compactMap { exitRequest -> StakingBalanceInfo? in
            guard let amount = exitRequest.totalAssets else { return nil }

            let actions: [StakingPendingActionInfo] = exitRequest.isClaimable
                ? [StakingPendingActionInfo(type: .withdraw, passthrough: .empty)]
                : []
            return StakingBalanceInfo(
                item: .ethereum,
                amount: amount,
                balanceType: exitRequest.isClaimable ? .unstaked : .unbonding(date: nil),
                validatorAddress: response.vaultAddress,
                actions: actions
            )
        }

        balances.append(contentsOf: unstakingBalances)
        return balances
    }

    func mapToBalancesInfo(from response: P2PDTO.RewardsHistory.RewardsHistoryInfo) -> [StakingBalanceInfo] {
        guard let lastRewards = response.rewards.last else { return [] }

        return [
            StakingBalanceInfo(
                item: .ethereum,
                amount: lastRewards.rewards,
                balanceType: .rewards,
                validatorAddress: response.vaultAddress,
                actions: []
            ),
        ]
    }

    func mapToStakingTransactionInfo(
        from response: P2PDTO.PrepareTransaction.PrepareTransactionInfo,
        walletAddress: String
    ) throws -> StakingTransactionInfo {
        let ethereumCompiledTransaction = EthereumCompiledTransaction(
            from: walletAddress,
            gasLimit: response.unsignedTransaction.gasLimit,
            to: response.unsignedTransaction.to,
            data: response.unsignedTransaction.data,
            nonce: response.unsignedTransaction.nonce,
            type: 0,
            maxFeePerGas: response.unsignedTransaction.maxFeePerGas,
            maxPriorityFeePerGas: response.unsignedTransaction.maxPriorityFeePerGas,
            gasPrice: nil,
            chainId: response.unsignedTransaction.chainId,
            value: response.unsignedTransaction.value
        )
        return try StakingTransactionInfo(
            id: "",
            actionId: "",
            network: "",
            unsignedTransactionData: ethereumCompiledTransaction,
            fee: fee(from: response.unsignedTransaction),
            type: "",
            status: "",
            stepIndex: 0
        )
    }

    func mapToValidatorInfo(from vault: P2PDTO.Vaults.Vault) -> ValidatorInfo {
        ValidatorInfo(
            address: vault.vaultAddress,
            name: vault.displayName,
            preferred: true,
            partner: false,
            iconURL: nil,
            rewardType: .apy,
            rewardRate: vault.apy ?? .zero,
            status: .active
        )
    }

    private func fee(from unsignedTransaction: P2PDTO.UnsignedTransaction) throws -> Decimal {
        guard let gasLimit = Decimal(stringValue: unsignedTransaction.gasLimit),
              let maxFeePerGas = Decimal(stringValue: unsignedTransaction.maxFeePerGas) else {
            throw P2PStakingAPIError.failedToGetFee
        }
        let feeWEI = gasLimit * maxFeePerGas
        return feeWEI / 10e18
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
