//
//  SendGenericFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemStaking

protocol SendGenericFlowFactory {
    func make(router: any SendRoutable, coordinatorStateProvider: SendCoordinatorStateProvider) -> SendViewModel
}

struct SendFactory {
    func flowFactory(options: SendCoordinator.Options) -> any SendGenericFlowFactory {
        switch options.type {
        case .send(let sourceToken, let parameters):
            return SendWithSwapFlowFactory(
                sourceToken: sourceToken,
                predefinedSendParameters: parameters,
                coordinatorSource: options.source
            )

        case .swap(.from(let sourceToken, let receiveToken)):
            return SwapFlowFactory(sourceToken: sourceToken, receiveToken: receiveToken)

        case .swap(.to(let receiveToken)):
            return SwapFlowFactory(receiveToken: receiveToken)

        case .swap(.deferredPairResolution(let source, let resolver)):
            return SwapFlowFactory(sourceToken: source, receiveToken: nil, swapTokenPairResolver: resolver)

        case .nft(let transferableToken, let parameters):
            return TransferNFTFlowFactory(
                transferableToken: transferableToken,
                nftAssetStepBuilder: NFTAssetStepBuilder(
                    asset: parameters.asset,
                    collection: parameters.collection
                )
            )

        case .sell(let transferableToken, let parameters):
            return TransferSellFlowFactory(
                transferableToken: transferableToken,
                sellParameters: parameters
            )

        // V2 staking (Feature.stakingFlowV2) — one factory for every staking action. When the toggle is
        // off these `where` cases don't match and the flow falls through to the legacy cases below.
        case .staking(let stakingableToken, let manager, let walletModelDependenciesProvider, _)
            where FeatureProvider.isAvailable(.stakingFlowV2):
            return StakeFactory(
                stakingableToken: stakingableToken,
                manager: manager,
                // Default action with full available amount; the provider's step plan decides whether
                // the amount is editable (most chains) or fixed (Cardano).
                action: StakingAction(
                    amount: stakingableToken.availableBalanceProvider.balanceType.value ?? 0,
                    targetType: .empty,
                    type: .stake
                ),
                walletModelDependenciesProvider: walletModelDependenciesProvider
            )

        case .restaking(let stakingableToken, let manager, let action) where FeatureProvider.isAvailable(.stakingFlowV2):
            return StakeFactory(stakingableToken: stakingableToken, manager: manager, action: action, walletModelDependenciesProvider: nil)

        case .unstaking(let stakingableToken, let manager, let action) where FeatureProvider.isAvailable(.stakingFlowV2):
            return StakeFactory(stakingableToken: stakingableToken, manager: manager, action: action, walletModelDependenciesProvider: nil)

        case .stakingSingleAction(let stakingableToken, let manager, let action) where FeatureProvider.isAvailable(.stakingFlowV2):
            return StakeFactory(stakingableToken: stakingableToken, manager: manager, action: action, walletModelDependenciesProvider: nil)

        // Legacy staking flows (removed with the stakingFlowV2 toggle).

        // We are using restaking flow here because it doesn't allow to edit amount
        case .staking(let stakingableToken, let manager, _, let stakingParams) where !stakingParams.isStakingAmountEditable:
            return RestakingFlowFactory(
                stakingableToken: stakingableToken,
                manager: manager,
                // Default action with full available amount
                action: StakingAction(
                    amount: stakingableToken.availableBalanceProvider.balanceType.value ?? 0,
                    targetType: .empty,
                    type: .stake
                )
            )

        case .staking(let stakingableToken, let manager, let walletModelDependenciesProvider, _):
            return StakingFlowFactory(
                stakingableToken: stakingableToken,
                manager: manager,
                walletModelDependenciesProvider: walletModelDependenciesProvider
            )

        case .restaking(let stakingableToken, let manager, let action):
            return RestakingFlowFactory(
                stakingableToken: stakingableToken,
                manager: manager,
                action: action
            )

        case .unstaking(let stakingableToken, let manager, let action):
            return UnstakingFlowFactory(
                stakingableToken: stakingableToken,
                manager: manager,
                action: action
            )

        case .stakingSingleAction(let stakingableToken, let manager, let action):
            return StakingSingleActionFlowFactory(
                stakingableToken: stakingableToken,
                manager: manager,
                action: action
            )

        case .onramp(let sourceToken, let parameters):
            return OnrampFlowFactory(
                sourceToken: sourceToken,
                parameters: parameters,
                coordinatorSource: options.source
            )
        }
    }
}
