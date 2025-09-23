//
//  SendNewFinishStepBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct SendNewFinishStepBuilder {
    typealias ReturnValue = SendNewFinishStep

    let tokenItem: TokenItem
    let coordinator: SendRoutable

    func makeSendFinishStep(
        input: SendFinishInput,
        sendFinishAnalyticsLogger: SendFinishAnalyticsLogger,
        sendAmountFinishViewModel: SendNewAmountFinishViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendFeeFinishViewModel: SendFeeFinishViewModel?,
    ) -> ReturnValue {
        let viewModel = SendNewFinishViewModel(
            input: input,
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            nftAssetCompactViewModel: nftAssetCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
            tokenItem: tokenItem,
            coordinator: coordinator
        )

        let step = SendNewFinishStep(viewModel: viewModel)
        return step
    }
}
