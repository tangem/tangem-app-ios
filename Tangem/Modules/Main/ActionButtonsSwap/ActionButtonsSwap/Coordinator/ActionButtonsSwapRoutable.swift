//
//  ActionButtonsSwapRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsSwapRoutable: AnyObject {
    func openExpress(
        for sourceWalletModel: WalletModel,
        and destinationWalletModel: WalletModel,
        with userWalletModel: UserWalletModel
    )
    func dismiss()
}
