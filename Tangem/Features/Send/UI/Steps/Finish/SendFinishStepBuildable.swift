//
//  SendFinishStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization

protocol SendFinishStepBuildable {
    var finishIO: SendFinishStepBuilder.IO { get }
    var finishTypes: SendFinishStepBuilder.Types { get }
    var finishDependencies: SendFinishStepBuilder.Dependencies { get }
}

extension SendFinishStepBuildable {
    func makeSendFinishStep(
        sendAmountFinishViewModel: SendAmountFinishViewModel? = nil,
        nftAssetCompactViewModel: NFTAssetCompactViewModel? = nil,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel? = nil,
        stakingTargetsCompactViewModel: StakingTargetsCompactViewModel? = nil,
        sendFeeFinishViewModel: SendFeeFinishViewModel? = nil,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel? = nil,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel? = nil,
        router: SendRoutable,
    ) -> SendFinishStepBuilder.ReturnValue {
        SendFinishStepBuilder.make(
            io: finishIO,
            types: finishTypes,
            dependencies: finishDependencies,
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            stakingTargetsCompactViewModel: stakingTargetsCompactViewModel,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            onrampStatusCompactViewModel: onrampStatusCompactViewModel,
            router: router,
        )
    }
}

enum SendFinishStepBuilder {
    struct IO {
        let input: SendFinishInput
    }

    struct Types {
        let title: String
        let tokenItem: TokenItem

        init(
            title: String = Localization.sentTransactionSentTitle,
            tokenItem: TokenItem
        ) {
            self.title = title
            self.tokenItem = tokenItem
        }
    }

    struct Dependencies {
        let analyticsLogger: any SendFinishAnalyticsLogger
    }

    typealias ReturnValue = SendFinishStep

    static func make(
        io: IO,
        types: Types,
        dependencies: Dependencies,
        sendAmountFinishViewModel: SendAmountFinishViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        stakingTargetsCompactViewModel: StakingTargetsCompactViewModel?,
        sendFeeFinishViewModel: SendFeeFinishViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?,
        router: SendRoutable,
    ) -> ReturnValue {
        let settings = SendFinishViewModel.Settings(
            title: types.title,
            possibleToShowExploreButtons: !types.tokenItem.blockchain.isTransactionAsync
        )

        let viewModel = SendFinishViewModel(
            input: io.input,
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            stakingTargetsCompactViewModel: stakingTargetsCompactViewModel,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            onrampStatusCompactViewModel: onrampStatusCompactViewModel,
            settings: settings,
            analyticsLogger: dependencies.analyticsLogger,
            coordinator: router
        )

        let step = SendFinishStep(viewModel: viewModel)
        return step
    }
}
