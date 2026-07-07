//
//  EarnAddTokenRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol EarnAddTokenRoutable: AnyObject, AddTokenFlowRoutable {
    func presentTokenDetails(by walletModel: any WalletModel, with userWalletModel: UserWalletModel)

    /// Navigation right after a token was successfully added through the Earn flow.
    /// Distinct from `presentTokenDetails` so that a yield-intent flow can route straight
    /// to the Yield onboarding instead of the token details screen.
    func presentAfterAdd(by walletModel: any WalletModel, with userWalletModel: UserWalletModel)
}

extension EarnAddTokenRoutable {
    func presentAfterAdd(by walletModel: any WalletModel, with userWalletModel: UserWalletModel) {
        presentTokenDetails(by: walletModel, with: userWalletModel)
    }
}
