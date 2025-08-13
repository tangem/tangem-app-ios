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

    func makeSendFinishStep(
        input: SendFinishInput,
        sendFinishAnalyticsLogger: SendFinishAnalyticsLogger,
        sendAmountFinishViewModel: SendNewAmountFinishViewModel?,
        sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?,
        sendFeeFinishViewModel: SendFeeFinishViewModel?,
    ) -> ReturnValue {
        let viewModel = SendNewFinishViewModel(
            input: input,
            sendAmountFinishViewModel: sendAmountFinishViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendFeeFinishViewModel: sendFeeFinishViewModel,
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
        )

        let step = SendNewFinishStep(viewModel: viewModel)
        return step
    }
}
