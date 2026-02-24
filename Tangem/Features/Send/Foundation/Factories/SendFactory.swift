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
        let baseDataBuilderFactory = SendBaseDataBuilderFactory(
            walletModel: options.input.walletModel,
            userWalletInfo: options.input.userWalletInfo
        )

        switch options.type {
        case .send(let sourceToken):
            return SendFlowFactory(
                sourceToken: sourceToken,
                baseDataBuilderFactory: baseDataBuilderFactory,
                source: ExpressInteractorWalletModelWrapper(
                    userWalletInfo: sourceToken.userWalletInfo,
                    walletModel: options.input.walletModel,
                    expressOperationType: .swapAndSend
                )
            )

        case .swap(let sourceToken):
            return SwapFlowFactory(
                sourceToken: sourceToken,
                baseDataBuilderFactory: baseDataBuilderFactory
            )

        case .nft(let sourceToken, let parameters):
            return NFTFlowFactory(
                sourceToken: sourceToken,
                nftAssetStepBuilder: NFTAssetStepBuilder(
                    asset: parameters.asset,
                    collection: parameters.collection
                ),
                baseDataBuilderFactory: baseDataBuilderFactory,
                source: ExpressInteractorWalletModelWrapper(
                    userWalletInfo: sourceToken.userWalletInfo,
                    walletModel: options.input.walletModel,
                    expressOperationType: .swapAndSend
                )
            )

        case .sell(let sourceToken, let parameters):
            return SellFlowFactory(
                sourceToken: sourceToken,
                sellParameters: parameters,
                baseDataBuilderFactory: baseDataBuilderFactory,
                source: ExpressInteractorWalletModelWrapper(
                    userWalletInfo: sourceToken.userWalletInfo,
                    walletModel: options.input.walletModel,
                    expressOperationType: .swapAndSend
                )
            )

        // We are using restaking flow here because it doesn't allow to edit amount
        case .staking(let sourceToken, let manager, let stakingParams) where !stakingParams.isStakingAmountEditable:
            return RestakingFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                // Default action with full available amount
                action: StakingAction(
                    amount: sourceToken.availableBalanceProvider.balanceType.value ?? 0,
                    targetType: .empty,
                    type: .stake
                ),
                baseDataBuilderFactory: baseDataBuilderFactory,
            )

        case .staking(let sourceToken, let manager, _):
            return StakingFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                baseDataBuilderFactory: baseDataBuilderFactory,
                allowanceServiceFactory: AllowanceServiceFactory(
                    walletModel: options.input.walletModel,
                    transactionDispatcherProvider: sourceToken.transactionDispatcherProvider
                ),
                walletModelDependenciesProvider: options.input.walletModel
            )

        case .restaking(let sourceToken, let manager, let action):
            return RestakingFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                action: action,
                baseDataBuilderFactory: baseDataBuilderFactory,
            )

        case .unstaking(let sourceToken, let manager, let action):
            return UnstakingFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                action: action,
                baseDataBuilderFactory: baseDataBuilderFactory,
            )

        case .stakingSingleAction(let sourceToken, let manager, let action):
            return StakingSingleActionFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                action: action,
                baseDataBuilderFactory: baseDataBuilderFactory,
            )

        case .onramp(let sourceToken, let parameters):
            return OnrampFlowFactory(
                sourceToken: sourceToken,
                parameters: parameters,
                coordinatorSource: options.source,
                baseDataBuilderFactory: baseDataBuilderFactory
            )
        }
    }
}
