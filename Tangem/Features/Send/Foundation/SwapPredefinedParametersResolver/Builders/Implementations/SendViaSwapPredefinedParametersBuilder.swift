//
//  SendViaSwapPredefinedParametersBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SendViaSwapPredefinedParametersBuilder: SwapPredefinedParametersBuilder {
    let sourceToken: SendSwapableToken

    func make() -> PredefinedSwapParameters {
        PredefinedSwapParameters(
            userWalletInfo: sourceToken.userWalletInfo,
            source: .resolved(sourceToken),
            receive: .userSelection
        )
    }
}
