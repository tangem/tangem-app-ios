//
//  MainSwapPredefinedParametersBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MainSwapPredefinedParametersBuilder: SwapPredefinedParametersBuilder {
    let userWalletModel: any UserWalletModel

    func make() -> PredefinedSwapParameters {
        PredefinedSwapParameters(
            userWalletInfo: userWalletModel.userWalletInfo,
            source: MainSwapSourceResolver(userWalletModel: userWalletModel),
            receive: .userSelection
        )
    }
}
