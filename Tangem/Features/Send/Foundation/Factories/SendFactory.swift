//
//  SendGenericFlowFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemStaking

protocol SendGenericFlowFactory {
    func make(router: any SendRoutable) -> SendViewModel
}

struct SendFactory {
    func flowFactory(options: SendCoordinator.Options) -> any SendGenericFlowFactory {
        switch options.type {
        case .send(let sourceToken):
            return SendWithSwapFlowFactory(sourceToken: sourceToken)

        case .swap(.from(let sourceToken, let receiveToken)):
            return SwapFlowFactory(sourceToken: sourceToken, receiveToken: receiveToken)

        case .swap(.to(let receiveToken)):
            return SwapFlowFactory(receiveToken: receiveToken)

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
