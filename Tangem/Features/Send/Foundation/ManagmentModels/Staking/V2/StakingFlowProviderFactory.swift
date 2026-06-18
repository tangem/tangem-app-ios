//
//  StakingFlowProviderFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

/// Selects the per-network staking flow entity. Adding a new network is a new `case` here plus its
/// entity — the only flow-layer edits a chain requires.
enum StakingFlowProviderFactory {
    static func make(
        network: StakingNetworkType,
        contractAddress: String?,
        action: StakingAction,
        stages: StakingFlowStages,
        minAmountValidator: SendAmountValidator,
        allowanceService: AllowanceService?,
        tokenFeeProvidersManager: TokenFeeProvidersManager
    ) -> StakingFlowProvider {
        switch network {
        case .solana:
            return SolanaStakingFlowProvider(action: action, stages: stages)
        case .cosmos:
            return CosmosStakingFlowProvider(action: action, stages: stages)
        case .kava, .near, .polkadot:
            assertionFailure("Staking is not supported for \(network)")
            return CosmosStakingFlowProvider(action: action, stages: stages)
        case .bsc:
            return BSCStakingFlowProvider(action: action, stages: stages)
        case .tron:
            return TronStakingFlowProvider(action: action, stages: stages)
        case .ton:
            return TONStakingFlowProvider(action: action, stages: stages)
        case .cardano:
            return CardanoStakingFlowProvider(action: action, stages: stages, minAmountValidator: minAmountValidator)
        case .ethereum:
            // No contract address → P2P liquid staking; otherwise a StakeKit token position (e.g. MATIC).
            if contractAddress == nil {
                return EthereumP2PStakingFlowProvider(action: action, stages: stages)
            }
            return EthereumStakingFlowProvider(
                action: action,
                stages: stages,
                allowanceService: allowanceService,
                tokenFeeProvidersManager: tokenFeeProvidersManager
            )
        }
    }
}
