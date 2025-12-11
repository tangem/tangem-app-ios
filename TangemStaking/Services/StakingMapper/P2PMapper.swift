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
                    validatorAddress: response.vaultAddress,
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
                    validatorAddress: response.vaultAddress,
                    actions: [StakingPendingActionInfo(type: .withdraw, passthrough: .empty)]
                )
            )
        }

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

    func mapToValidatorInfo(from vault: P2PDTO.Vaults.Vault) -> ValidatorInfo {
        ValidatorInfo(
            address: vault.vaultAddress,
            name: vault.displayName,
            preferred: true,
            partner: false,
            iconURL: nil,
            rewardType: rewardType,
            rewardRate: vault.apy ?? .zero,
            status: .active
        )
    }

    private func fee(from unsignedTransaction: P2PDTO.UnsignedTransaction) throws -> Decimal {
        guard let gasLimit = BigUInt(unsignedTransaction.gasLimit),
              let maxFeePerGas = BigUInt(unsignedTransaction.maxFeePerGas),
              let maxPriorityFeePerGas = BigUInt(unsignedTransaction.maxPriorityFeePerGas) else {
            throw P2PStakingAPIError.failedToGetFee
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
