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
            if let policy = sourceToken.jointAccountPolicy {
                return JointAccountSendFlowFactory(
                    transferableToken: sourceToken,
                    policy: policy,
                    predefinedSendParameters: parameters,
                    coordinatorSource: options.source
                )
            }

            return SendWithSwapFlowFactory(
                sourceToken: sourceToken,
                predefinedSendParameters: parameters,
                shouldStartFromTokenList: options.shouldStartFromTokenList,
                coordinatorSource: options.source
            )

        case .swap(let parameters):
            return SwapFlowFactory(parameters: parameters)

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

        case .staking(let stakingableToken, let manager, let walletModelDependenciesProvider):
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

        case .restaking(let stakingableToken, let manager, let action):
            return StakeFactory(stakingableToken: stakingableToken, manager: manager, action: action, walletModelDependenciesProvider: nil)

        case .unstaking(let stakingableToken, let manager, let action):
            return StakeFactory(stakingableToken: stakingableToken, manager: manager, action: action, walletModelDependenciesProvider: nil)

        case .stakingSingleAction(let stakingableToken, let manager, let action):
            return StakeFactory(stakingableToken: stakingableToken, manager: manager, action: action, walletModelDependenciesProvider: nil)

        case .onramp(let sourceToken, let parameters):
            return OnrampFlowFactory(
                sourceToken: sourceToken,
                parameters: parameters,
                coordinatorSource: options.source
            )
        }
    }
}
