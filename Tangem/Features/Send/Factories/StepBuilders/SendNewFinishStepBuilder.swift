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
        sendAmountCompactViewModel: SendTokenAmountCompactViewModel?,
        sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?,
        sendSwapProviderFinishViewModel: SendSwapProviderFinishViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
    ) -> ReturnValue {
        let viewModel = SendNewFinishViewModel(
            input: input,
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendSwapProviderFinishViewModel: sendSwapProviderFinishViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
        )

        let step = SendNewFinishStep(viewModel: viewModel)
        return step
    }
}
