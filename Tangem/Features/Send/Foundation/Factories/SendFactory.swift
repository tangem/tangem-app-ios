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
        case .send(let sourceToken, _) where FeatureProvider.isAvailable(.swapRefactoring):
            return SendWithSwapFlowFactory(sourceToken: sourceToken)

        case .send(let sourceToken, let source):
            return SendFlowFactory(sourceToken: sourceToken, source: source)

        case .swap(.from(let sourceToken, let receiveToken)):
            return SwapFlowFactory(sourceToken: sourceToken, receiveToken: receiveToken)

        case .nft(let sourceToken, _, let parameters) where FeatureProvider.isAvailable(.swapRefactoring):
            return TransferNFTFlowFactory(
                sourceToken: sourceToken,
                nftAssetStepBuilder: NFTAssetStepBuilder(
                    asset: parameters.asset,
                    collection: parameters.collection
                ),
            )

        case .nft(let sourceToken, let source, let parameters):
            return NFTFlowFactory(
                sourceToken: sourceToken,
                nftAssetStepBuilder: NFTAssetStepBuilder(
                    asset: parameters.asset,
                    collection: parameters.collection
                ),
                source: source
            )

        case .sell(let sourceToken, _, let parameters) where FeatureProvider.isAvailable(.swapRefactoring):
            return TransferSellFlowFactory(
                sourceToken: sourceToken,
                sellParameters: parameters,
            )

        case .sell(let sourceToken, let source, let parameters):
            return SellFlowFactory(
                sourceToken: sourceToken,
                sellParameters: parameters,
                source: source
            )

        // We are using restaking flow here because it doesn't allow to edit amount
        case .staking(let sourceToken, let manager, _, let stakingParams) where !stakingParams.isStakingAmountEditable:
            return RestakingFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                // Default action with full available amount
                action: StakingAction(
                    amount: sourceToken.availableBalanceProvider.balanceType.value ?? 0,
                    targetType: .empty,
                    type: .stake
                )
            )

        case .staking(let sourceToken, let manager, let walletModelDependenciesProvider, _):
            return StakingFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                walletModelDependenciesProvider: walletModelDependenciesProvider
            )

        case .restaking(let sourceToken, let manager, let action):
            return RestakingFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                action: action
            )

        case .unstaking(let sourceToken, let manager, let action):
            return UnstakingFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                action: action
            )

        case .stakingSingleAction(let sourceToken, let manager, let action):
            return StakingSingleActionFlowFactory(
                sourceToken: sourceToken,
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
