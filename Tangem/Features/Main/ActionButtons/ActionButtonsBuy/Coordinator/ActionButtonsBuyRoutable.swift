//
//  ActionButtonsBuyRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonsBuyRoutable: AnyObject {
    func openOnramp(walletModel: any WalletModel, userWalletModel: UserWalletModel)
    func openOnramp(input: SendInput)
    func openAddToPortfolio(_ infoModel: HotCryptoAddToPortfolioModel)
    func closeAddToPortfolio()
    func dismiss()
}
