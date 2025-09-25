//
//  SendFeeStepBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendFeeStepBuilder {
    typealias IO = (input: SendFeeInput, output: SendFeeOutput)

    let walletModel: any WalletModel
    let builder: SendDependenciesBuilder

    func makeSendFeeCompactViewModel(input: SendFeeInput) -> SendFeeCompactViewModel {
        .init(
            input: input,
            feeTokenItem: walletModel.feeTokenItem,
            isFeeApproximate: builder.isFeeApproximate()
        )
    }
}
