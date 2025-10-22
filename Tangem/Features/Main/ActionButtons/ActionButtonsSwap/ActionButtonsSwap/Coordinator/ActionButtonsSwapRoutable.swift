//
//  ActionButtonsSwapRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsSwapRoutable: AnyObject {
    func openExpress(input: CommonExpressModulesFactory.InputModel)
    func dismiss()
    func showYieldNotificationIfNeeded(for walletModel: any WalletModel, completion: (() -> Void)?)
}
