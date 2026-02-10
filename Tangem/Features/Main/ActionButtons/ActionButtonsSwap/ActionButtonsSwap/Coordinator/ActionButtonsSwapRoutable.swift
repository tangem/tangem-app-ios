//
//  ActionButtonsSwapRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsSwapRoutable: AnyObject {
    func openExpress(input: ExpressDependenciesInput)
    func dismiss()
    func showYieldNotificationIfNeeded(for walletModel: any WalletModel, completion: (() -> Void)?)
    /// Opens the add-token flow for an external token selected from search results
    @MainActor
    func openAddTokenFlowForExpress(inputData: ExpressAddTokenInputData)
}
