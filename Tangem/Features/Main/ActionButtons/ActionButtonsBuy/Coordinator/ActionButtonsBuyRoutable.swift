//
//  ActionButtonsBuyRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonsBuyRoutable: AnyObject {
    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters)

    func openAddFunds(userWalletInfo: UserWalletInfo, walletModel: any WalletModel)

    func openAddToPortfolio(viewModel: HotCryptoAddToPortfolioBottomSheetViewModel)

    func openAddHotToken(hotToken: HotCryptoToken, userWalletModels: [UserWalletModel])

    func closeAddToPortfolio()

    func dismiss()
}
