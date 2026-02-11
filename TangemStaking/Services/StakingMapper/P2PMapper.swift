//
//  P2PMapper.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt

struct P2PMapper {
    let item: StakingTokenItem = .ethereum
    let rewardType: RewardType = .apy

    func mapToYieldInfo(from response: P2PDTO.Vaults.VaultsInfo) throws -> StakingYieldInfo {
        let vaults = response.vaults
            .filter { !$0.isSmoothingPool && !$0.isPrivate }
            .map { mapToStakingTargetInfo(from: $0) }

        let rewardRateValues = RewardRateValues(
            aprs: vaults.compactMap(\.rewardRate),
            rewardRate: .zero
        )

        let maximumStakeAmount = vaults.compactMap { $0.maximumStakeAmount }.compactMap { $0 }.min()

        return StakingYieldInfo(
            id: item.network.rawValue,
            isAvailable: true,
            rewardType: rewardType,
            rewardRateValues: rewardRateValues,
            enterMinimumRequirement: StakingConstants.p2pEnterMinimumRequirements,
            exitMinimumRequirement: .zero,
            targets: vaults,
            preferredTargets: vaults,
            item: item,
            unbondingPeriod: .variable(minDays: 1, maxDays: 4),
            warmupPeriod: .constant(days: 0),
            rewardClaimingType: .auto,
            rewardScheduleType: .daily,
            maximumStakeAmount: maximumStakeAmount
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
                    targetAddress: response.vaultAddress,
                    actions: []
                )
            )
        }

        let unstakingAmount = response.exitQueue.requests
            .filter { !$0.isClaimable }
            .reduce(into: Decimal.zero) { partialResult, exitRequest in
                partialResult += exitRequest.totalAssets ?? .zero
            }

        if !unstakingAmount.isZero {
            balances.append(
                StakingBalanceInfo(
                    item: .ethereum,
                    amount: unstakingAmount,
                    balanceType: .unbonding(date: nil),
                    targetAddress: response.vaultAddress,
                    actions: []
                )
            )
        }

        let unstakedAmount = response.exitQueue.requests
            .filter { $0.isClaimable }
            .reduce(into: Decimal.zero) { partialResult, exitRequest in
                partialResult += exitRequest.totalAssets ?? .zero
            }

        if !unstakedAmount.isZero {
            balances.append(
                StakingBalanceInfo(
                    item: .ethereum,
                    amount: unstakedAmount,
                    balanceType: .unstaked,
                    targetAddress: response.vaultAddress,
                    actions: [StakingPendingActionInfo(type: .withdraw, passthrough: .empty)]
                )
            )
        }

        if let rewards = response.stake.totalEarnedAssets, rewards > .zero {
            balances.append(
                StakingBalanceInfo(
                    item: .ethereum,
                    amount: rewards,
                    balanceType: .rewards,
                    targetAddress: response.vaultAddress,
                    actions: []
                )
            )
        }

        return balances
    }

    func mapToStakingTransactionInfo(
        from response: P2PDTO.PrepareTransaction.PrepareTransactionInfo,
        walletAddress: String
    ) throws -> StakingTransactionInfo {
        let unsignedTx = response.unsignedTransaction

        let ethereumCompiledTransaction = EthereumCompiledTransactionData(
            from: walletAddress,
            gasLimit: unsignedTx.gasLimit,
            to: unsignedTx.to,
            data: unsignedTx.data,
            nonce: unsignedTx.nonce,
            maxFeePerGas: unsignedTx.maxFeePerGas,
            maxPriorityFeePerGas: unsignedTx.maxPriorityFeePerGas,
            gasPrice: nil,
            chainId: response.unsignedTransaction.chainId,
            value: unsignedTx.value
        )
        return try StakingTransactionInfo(
            network: item.name,
            unsignedTransactionData: .compiledEthereum(ethereumCompiledTransaction),
            fee: fee(from: response.unsignedTransaction),
        )
    }

    func mapToStakingTargetInfo(from vault: P2PDTO.Vaults.Vault) -> StakingTargetInfo {
        StakingTargetInfo(
            address: vault.vaultAddress,
            name: vault.displayName,
            preferred: true,
            partner: false,
            iconURL: nil,
            rewardType: rewardType,
            rewardRate: vault.apy ?? .zero,
            status: .active,
            maximumStakeAmount: vault.totalAssets.flatMap { totalAssets in
                vault.capacity.flatMap { capacity in
                    capacity - totalAssets
                }
            }
        )
    }

    private func fee(from unsignedTransaction: P2PDTO.UnsignedTransaction) throws -> Decimal {
        guard let gasLimit = BigUInt(unsignedTransaction.gasLimit),
              let maxFeePerGas = BigUInt(unsignedTransaction.maxFeePerGas),
              let maxPriorityFeePerGas = BigUInt(unsignedTransaction.maxPriorityFeePerGas) else {
            throw P2PStakingError.failedToGetFee
        }

        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: gasLimit,
            baseFee: maxFeePerGas,
            priorityFee: maxPriorityFeePerGas
        )

        return feeParameters.calculateFee(decimalValue: pow(Decimal(10), item.decimals))
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
