//
//  SwapAvailabilityChecker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol SwapAvailabilityChecker {
    func isSwapAvailable(walletModel: any WalletModel) -> Bool
}

struct CommonSwapAvailabilityChecker: SwapAvailabilityChecker {
    private let userWalletInfo: UserWalletInfo

    init(userWalletInfo: UserWalletInfo) {
        self.userWalletInfo = userWalletInfo
    }

    func isSwapAvailable(walletModel: any WalletModel) -> Bool {
        TokenActionAvailabilityProvider(
            userWalletConfig: userWalletInfo.config,
            walletModel: walletModel
        ).isSwapAvailable
    }
}
