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
        let sourceTokenFactory = SendSourceTokenFactory(
            userWalletInfo: options.input.userWalletInfo,
            walletModel: options.input.walletModel
        )

        let provider = makeTokenHeaderProvider(options: options)
        let sourceToken = sourceTokenFactory.makeSourceToken(tokenHeaderProvider: provider)

        let baseDataBuilderFactory = SendBaseDataBuilderFactory(
            walletModel: options.input.walletModel,
            userWalletInfo: options.input.userWalletInfo
        )

        switch options.type {
        case .send:
            return SendFlowFactory(
                sourceToken: sourceToken,
                sendingWalletDestinationStepDataInput: .init(
                    walletAddresses: options.input.walletModel.addresses.map(\.value),
                    suggestedWallets: SendSuggestedWalletsFactory().makeSuggestedWallets(walletModel: options.input.walletModel),
                    walletModelHistoryUpdater: options.input.walletModel
                ),
                baseDataBuilderFactory: baseDataBuilderFactory,
                source: ExpressInteractorWalletModelWrapper(
                    userWalletInfo: sourceToken.userWalletInfo,
                    walletModel: options.input.walletModel,
                    expressOperationType: .swapAndSend
                )
            )

        case .swap:
            return SwapFlowFactory(
                sourceToken: sourceToken,
                baseDataBuilderFactory: baseDataBuilderFactory,
                source: ExpressInteractorWalletModelWrapper(
                    userWalletInfo: sourceToken.userWalletInfo,
                    walletModel: options.input.walletModel,
                    expressOperationType: .swap
                )
            )

        case .nft(let parameters):
            return NFTFlowFactory(
                sourceToken: sourceToken,
                nftAssetStepBuilder: NFTAssetStepBuilder(
                    asset: parameters.asset,
                    collection: parameters.collection
                ),
                sendingWalletDestinationStepDataInput: .init(
                    walletAddresses: options.input.walletModel.addresses.map(\.value),
                    suggestedWallets: SendSuggestedWalletsFactory().makeSuggestedWallets(walletModel: options.input.walletModel),
                    walletModelHistoryUpdater: options.input.walletModel
                ),
                baseDataBuilderFactory: baseDataBuilderFactory,
                source: ExpressInteractorWalletModelWrapper(
                    userWalletInfo: sourceToken.userWalletInfo,
                    walletModel: options.input.walletModel,
                    expressOperationType: .swapAndSend
                )
            )

        case .sell(let parameters):
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
        case .staking(let manager, let stakingParams) where !stakingParams.isStakingAmountEditable:
            return RestakingFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                // Default action with full available amount
                action: StakingAction(
                    amount: options.input.walletModel.availableBalanceProvider.balanceType.value ?? 0,
                    targetType: .empty,
                    type: .stake
                ),
                baseDataBuilderFactory: baseDataBuilderFactory,
            )

        case .staking(let manager, _):
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

        case .restaking(let manager, let action):
            return RestakingFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                action: action,
                baseDataBuilderFactory: baseDataBuilderFactory,
            )

        case .unstaking(let manager, let action):
            return UnstakingFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                action: action,
                baseDataBuilderFactory: baseDataBuilderFactory,
            )

        case .stakingSingleAction(let manager, let action):
            return StakingSingleActionFlowFactory(
                sourceToken: sourceToken,
                manager: manager,
                action: action,
                baseDataBuilderFactory: baseDataBuilderFactory,
            )

        case .onramp(let parameters):
            return OnrampFlowFactory(
                sourceToken: sourceToken,
                parameters: parameters,
                coordinatorSource: options.source,
                baseDataBuilderFactory: baseDataBuilderFactory,
                source: ExpressInteractorWalletModelWrapper(
                    userWalletInfo: sourceToken.userWalletInfo,
                    walletModel: options.input.walletModel,
                    expressOperationType: .onramp
                )
            )
        }
    }

    private func makeTokenHeaderProvider(options: SendCoordinator.Options) -> SendGenericTokenHeaderProvider {
        switch options.type {
        case .unstaking:
            return UnstakingTokenHeaderProvider()

        default:
            let flowActionType: SendFlowActionType = switch options.type {
            case .send, .nft, .sell: .send
            case .swap: .swap
            case .staking: .stake
            case .restaking(_, let action): action.type.sendFlowActionType
            case .unstaking: .unstake
            case .stakingSingleAction(_, let action): action.type.sendFlowActionType
            case .onramp: .onramp
            }

            return SendTokenHeaderProvider(
                userWalletInfo: options.input.userWalletInfo,
                account: options.input.walletModel.account,
                flowActionType: flowActionType
            )
        }
    }
}
