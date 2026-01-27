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
        case .send:
            SendFlowFactory(
                userWalletInfo: options.input.userWalletInfo,
                walletModel: options.input.walletModel
            )

        case .nft(let parameters):
            NFTFlowFactory(
                userWalletInfo: options.input.userWalletInfo,
                nftAssetStepBuilder: NFTAssetStepBuilder(
                    wallet: options.input.userWalletInfo.name,
                    asset: parameters.asset,
                    collection: parameters.collection
                ),
                walletModel: options.input.walletModel
            )

        case .sell(let parameters):
            SellFlowFactory(
                userWalletInfo: options.input.userWalletInfo,
                sellParameters: parameters,
                walletModel: options.input.walletModel
            )

        // We are using restaking flow here because it doesn't allow to edit amount
        case .staking(let manager, let stakingParams) where !stakingParams.isStakingAmountEditable:
            RestakingFlowFactory(
                userWalletInfo: options.input.userWalletInfo,
                manager: manager,
                // Default action with full available amount
                action: StakingAction(
                    amount: options.input.walletModel.availableBalanceProvider.balanceType.value ?? 0,
                    targetType: .empty,
                    type: .stake
                ),
                walletModel: options.input.walletModel,
            )

        case .staking(let manager, _):
            StakingFlowFactory(
                userWalletInfo: options.input.userWalletInfo,
                manager: manager,
                walletModel: options.input.walletModel,
            )

        case .restaking(let manager, let action):
            RestakingFlowFactory(
                userWalletInfo: options.input.userWalletInfo,
                manager: manager,
                action: action,
                walletModel: options.input.walletModel,
            )

        case .unstaking(let manager, let action):
            UnstakingFlowFactory(
                walletModel: options.input.walletModel,
                userWalletInfo: options.input.userWalletInfo,
                manager: manager,
                action: action
            )

        case .stakingSingleAction(let manager, let action):
            StakingSingleActionFlowFactory(
                walletModel: options.input.walletModel,
                userWalletInfo: options.input.userWalletInfo,
                manager: manager,
                action: action
            )

        case .onramp(let parameters):
            OnrampFlowFactory(
                userWalletInfo: options.input.userWalletInfo,
                parameters: parameters,
                source: options.source,
                walletModel: options.input.walletModel
            )
        }
    }
}
