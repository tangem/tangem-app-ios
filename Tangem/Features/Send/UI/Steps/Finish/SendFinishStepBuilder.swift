//
//  SendFinishStepBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendFinishStepBuilder {
    typealias ReturnValue = SendFinishStep

    let walletModel: any WalletModel
    let coordinator: any SendRoutable

    func makeSendFinishStep(
        input: SendFinishInput,
        sendFinishAnalyticsLogger: SendFinishAnalyticsLogger,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?
    ) -> ReturnValue {
        let viewModel = makeSendFinishViewModel(
            input: input,
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            onrampStatusCompactViewModel: onrampStatusCompactViewModel
        )

        let step = SendFinishStep(viewModel: viewModel)

        return step
    }
}

// MARK: - Private

private extension SendFinishStepBuilder {
    func makeSendFinishViewModel(
        input: SendFinishInput,
        sendFinishAnalyticsLogger: SendFinishAnalyticsLogger,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?
    ) -> SendFinishViewModel {
        SendFinishViewModel(
            input: input,
            tokenItem: walletModel.tokenItem,
            sendFinishAnalyticsLogger: sendFinishAnalyticsLogger,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            onrampAmountCompactViewModel: onrampAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel,
            onrampStatusCompactViewModel: onrampStatusCompactViewModel,
            coordinator: coordinator
        )
    }
}
