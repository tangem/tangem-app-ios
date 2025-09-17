//
//  SendFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemFoundation

struct SendFlowFactory {
    private let walletInfo: SendWalletInfo
    private let walletModel: any WalletModel
    private let source: SendCoordinator.Source

    private let builder: SendDependenciesBuilder

    init(input: SendDependenciesBuilder.Input, source: SendCoordinator.Source) {
        walletInfo = input.userWalletInfo
        walletModel = input.walletModel

        self.source = source

        builder = SendDependenciesBuilder(input: input)
    }

    func makeSendViewModel(router: SendRoutable) -> SendViewModel {
        let sendDestinationStepBuilder = SendDestinationStepBuilder(walletModel: walletModel, builder: builder)
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel, coordinator: router)

        let baseBuilder = SendFlowBaseBuilder(
            walletModel: walletModel,
            coordinatorSource: source,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendDestinationStepBuilder: sendDestinationStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(router: router)
    }

    func makeNFTSendViewModel(parameters: SendParameters.NonFungibleTokenParameters, router: SendRoutable) -> SendViewModel {
        let sendDestinationStepBuilder = SendDestinationStepBuilder(walletModel: walletModel, builder: builder)
        let sendAmountStepBuilder = NFTSendAmountStepBuilder(
            walletModel: walletModel,
            builder: builder,
            asset: parameters.asset,
            collection: parameters.collection
        )
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel, coordinator: router)

        let baseBuilder = NFTSendFlowBaseBuilder(
            walletModel: walletModel,
            coordinatorSource: source,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendDestinationStepBuilder: sendDestinationStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(router: router)
    }

    func makeNewNFTSendViewModel(parameters: SendParameters.NonFungibleTokenParameters, router: SendRoutable) -> SendViewModel {
        let sendDestinationStepBuilder = SendNewDestinationStepBuilder(builder: builder)
        let nftAssetStepBuilder = NFTAssetStepBuilder(wallet: walletInfo.name, asset: parameters.asset, collection: parameters.collection)
        let sendFeeStepBuilder = SendNewFeeStepBuilder(feeTokenItem: walletModel.feeTokenItem, builder: builder)
        let sendSummaryStepBuilder = SendNewSummaryStepBuilder(tokenItem: walletModel.tokenItem, builder: builder)
        let sendFinishStepBuilder = SendNewFinishStepBuilder(tokenItem: walletModel.tokenItem, coordinator: router)

        let baseBuilder = NewNFTSendFlowBaseBuilder(
            walletModel: walletModel,
            coordinatorSource: source,
            nftAssetStepBuilder: nftAssetStepBuilder,
            sendDestinationStepBuilder: sendDestinationStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(router: router)
    }

    func makeNewSendViewModel(router: SendRoutable) -> SendViewModel {
        let sendDestinationStepBuilder = SendNewDestinationStepBuilder(builder: builder)
        let sendAmountStepBuilder = SendNewAmountStepBuilder(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem, builder: builder)
        let sendFeeStepBuilder = SendNewFeeStepBuilder(feeTokenItem: walletModel.feeTokenItem, builder: builder)
        let swapProvidersBuilder = SendSwapProvidersBuilder(tokenItem: walletModel.tokenItem, builder: builder)
        let sendSummaryStepBuilder = SendNewSummaryStepBuilder(tokenItem: walletModel.tokenItem, builder: builder)
        let sendFinishStepBuilder = SendNewFinishStepBuilder(tokenItem: walletModel.tokenItem, coordinator: router)

        let baseBuilder = NewSendFlowBaseBuilder(
            walletModel: walletModel,
            coordinatorSource: source,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendDestinationStepBuilder: sendDestinationStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            swapProvidersBuilder: swapProvidersBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(router: router)
    }

    func makeSellViewModel(sellParameters: PredefinedSellParameters, router: SendRoutable) -> SendViewModel {
        let sendDestinationStepBuilder = SendDestinationStepBuilder(walletModel: walletModel, builder: builder)
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel, coordinator: router)

        let baseBuilder = SellFlowBaseBuilder(
            walletModel: walletModel,
            coordinatorSource: source,
            sendDestinationStepBuilder: sendDestinationStepBuilder,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(sellParameters: sellParameters, router: router)
    }

    func makeNewSellViewModel(sellParameters: PredefinedSellParameters, router: SendRoutable) -> SendViewModel {
        let sendFeeStepBuilder = SendNewFeeStepBuilder(feeTokenItem: walletModel.feeTokenItem, builder: builder)
        let sendSummaryStepBuilder = SendNewSummaryStepBuilder(tokenItem: walletModel.tokenItem, builder: builder)
        let sendFinishStepBuilder = SendNewFinishStepBuilder(tokenItem: walletModel.tokenItem, coordinator: router)

        let baseBuilder = NewSellFlowBaseBuilder(
            walletModel: walletModel,
            coordinatorSource: source,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(sellParameters: sellParameters, router: router)
    }

    func makeStakingViewModel(manager: some StakingManager, router: SendRoutable) -> SendViewModel {
        let stakingValidatorsStepBuilder = StakingValidatorsStepBuilder()
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel, coordinator: router)

        let baseBuilder = StakingFlowBaseBuilder(
            walletModel: walletModel,
            source: source,
            sendAmountStepBuilder: sendAmountStepBuilder,
            stakingValidatorsStepBuilder: stakingValidatorsStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(manager: manager, router: router)
    }

    func makeUnstakingViewModel(manager: some StakingManager, action: UnstakingModel.Action, router: SendRoutable) -> SendViewModel {
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel, coordinator: router)

        let baseBuilder = UnstakingFlowBaseBuilder(
            walletModel: walletModel,
            source: source,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(manager: manager, action: action, router: router)
    }

    func makeRestakingViewModel(manager: some StakingManager, action: RestakingModel.Action? = nil, router: SendRoutable) -> SendViewModel {
        let stakingValidatorsStepBuilder = StakingValidatorsStepBuilder()
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel, coordinator: router)

        let baseBuilder = RestakingFlowBaseBuilder(
            walletModel: walletModel,
            source: source,
            stakingValidatorsStepBuilder: stakingValidatorsStepBuilder,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(manager: manager, action: action, router: router)
    }

    func makeStakingSingleActionViewModel(manager: some StakingManager, action: UnstakingModel.Action, router: SendRoutable) -> SendViewModel {
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel, coordinator: router)

        let baseBuilder = StakingSingleActionFlowBaseBuilder(
            walletModel: walletModel,
            source: source,
            sendAmountStepBuilder: sendAmountStepBuilder,
            sendFeeStepBuilder: sendFeeStepBuilder,
            sendSummaryStepBuilder: sendSummaryStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(manager: manager, action: action, router: router)
    }

    func makeOnrampViewModel(parameters: PredefinedOnrampParameters, router: SendRoutable) -> SendViewModel {
        let onrampStepBuilder = OnrampStepBuilder(walletModel: walletModel)
        let onrampAmountBuilder = OnrampAmountBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel, coordinator: router)

        let baseBuilder = OnrampFlowBaseBuilder(
            walletModel: walletModel,
            source: source,
            onrampAmountBuilder: onrampAmountBuilder,
            onrampStepBuilder: onrampStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(parameters: parameters, router: router)
    }

    func makeNewOnrampViewModel(parameters: PredefinedOnrampParameters, router: SendRoutable) -> SendViewModel {
        let onrampStepBuilder = NewOnrampStepBuilder(walletModel: walletModel)
        let onrampAmountBuilder = OnrampAmountBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel, coordinator: router)

        let baseBuilder = NewOnrampFlowBaseBuilder(
            walletModel: walletModel,
            source: source,
            onrampAmountBuilder: onrampAmountBuilder,
            onrampStepBuilder: onrampStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(parameters: parameters, router: router)
    }
}

struct SendWalletInfo {
    let name: String
    let id: UserWalletId
    let config: UserWalletConfig
    let signer: TangemSigner
}
