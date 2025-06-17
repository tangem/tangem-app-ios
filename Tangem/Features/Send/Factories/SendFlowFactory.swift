//
//  SendFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct SendFlowFactory {
    private let userWalletModel: UserWalletModel
    private let walletModel: any WalletModel
    private let source: SendCoordinator.Source

    init(userWalletModel: UserWalletModel, walletModel: any WalletModel, source: SendCoordinator.Source) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
        self.source = source
    }

    func makeSendViewModel(router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let sendDestinationStepBuilder = SendDestinationStepBuilder(walletModel: walletModel, builder: builder)
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = SendFlowBaseBuilder(
            userWalletModel: userWalletModel,
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
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let sendDestinationStepBuilder = SendDestinationStepBuilder(walletModel: walletModel, builder: builder)
        let sendAmountStepBuilder = NFTSendAmountStepBuilder(
            walletModel: walletModel,
            builder: builder,
            asset: parameters.asset,
            collection: parameters.collection
        )
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = NFTSendFlowBaseBuilder(
            userWalletModel: userWalletModel,
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

    func makeNewSendViewModel(router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let sendDestinationStepBuilder = SendNewDestinationStepBuilder(
            tokenItem: walletModel.tokenItem,
            ignoredAddresses: walletModel.addresses.map(\.value),
            addressResolver: walletModel.addressResolver,
            builder: builder
        )
        let sendAmountStepBuilder = SendNewAmountStepBuilder(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem, builder: builder)
        let sendFeeStepBuilder = SendNewFeeStepBuilder(feeTokenItem: walletModel.feeTokenItem, builder: builder)
        let sendSummaryStepBuilder = SendNewSummaryStepBuilder(tokenItem: walletModel.tokenItem, builder: builder)
        let sendFinishStepBuilder = SendNewFinishStepBuilder()

        let baseBuilder = NewSendFlowBaseBuilder(
            userWalletModel: userWalletModel,
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

    func makeSellViewModel(sellParameters: PredefinedSellParameters, router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let sendDestinationStepBuilder = SendDestinationStepBuilder(walletModel: walletModel, builder: builder)
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = SellFlowBaseBuilder(
            userWalletModel: userWalletModel,
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

    func makeStakingViewModel(manager: some StakingManager, router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let stakingValidatorsStepBuilder = StakingValidatorsStepBuilder()
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = StakingFlowBaseBuilder(
            userWalletModel: userWalletModel,
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
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = UnstakingFlowBaseBuilder(
            userWalletModel: userWalletModel,
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
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let stakingValidatorsStepBuilder = StakingValidatorsStepBuilder()
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = RestakingFlowBaseBuilder(
            userWalletModel: userWalletModel,
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
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let sendAmountStepBuilder = SendAmountStepBuilder(walletModel: walletModel, builder: builder)
        let sendFeeStepBuilder = SendFeeStepBuilder(walletModel: walletModel, builder: builder)
        let sendSummaryStepBuilder = SendSummaryStepBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = StakingSingleActionFlowBaseBuilder(
            userWalletModel: userWalletModel,
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

    func makeOnrampViewModel(router: SendRoutable) -> SendViewModel {
        let builder = SendDependenciesBuilder(userWalletModel: userWalletModel, walletModel: walletModel)
        let onrampStepBuilder = OnrampStepBuilder(walletModel: walletModel)
        let onrampAmountBuilder = OnrampAmountBuilder(walletModel: walletModel, builder: builder)
        let sendFinishStepBuilder = SendFinishStepBuilder(walletModel: walletModel)

        let baseBuilder = OnrampFlowBaseBuilder(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            source: source,
            onrampAmountBuilder: onrampAmountBuilder,
            onrampStepBuilder: onrampStepBuilder,
            sendFinishStepBuilder: sendFinishStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(router: router)
    }
}
