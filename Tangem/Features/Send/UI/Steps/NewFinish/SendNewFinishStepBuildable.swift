//
//  SendNewFinishStepBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendNewFinishStepBuildable {
    var newFinishIO: SendNewFinishStepBuilder.IO { get }
    var newFinishTypes: SendNewFinishStepBuilder.Types { get }
    var newFinishDependencies: SendNewFinishStepBuilder.Dependencies { get }
}

extension SendNewFinishStepBuildable {
    func makeSendFinishStep(
        sendAmountFinishViewModel: SendNewAmountFinishViewModel? = nil,
        nftAssetCompactViewModel: NFTAssetCompactViewModel? = nil,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel? = nil,
        sendFeeFinishViewModel: SendFeeFinishViewModel? = nil,
        router: SendRoutable,
    ) -> SendNewFinishStepBuilder.ReturnValue {
        SendNewFinishStepBuilder.make(
            io: newFinishIO,
            types: newFinishTypes,
            dependencies: newFinishDependencies,
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            router: router,
        )
    }
}

enum SendNewFinishStepBuilder {
    struct IO {
        let input: SendFinishInput
    }

    struct Types {
        let tokenItem: TokenItem
    }

    struct Dependencies {
        let analyticsLogger: any SendFinishAnalyticsLogger
    }

    typealias ReturnValue = SendNewFinishStep

    static func make(
        io: IO,
        types: Types,
        dependencies: Dependencies,
        sendAmountFinishViewModel: SendNewAmountFinishViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendFeeFinishViewModel: SendFeeFinishViewModel?,
        router: SendRoutable,
    ) -> ReturnValue {
        let viewModel = SendNewFinishViewModel(
            input: io.input,
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            sendFinishAnalyticsLogger: dependencies.analyticsLogger,
            tokenItem: types.tokenItem,
            coordinator: router
        )

        let step = SendNewFinishStep(viewModel: viewModel)
        return step
    }
}
