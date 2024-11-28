//
//  MarketsPortfolioContainerRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsPortfolioContainerRoutable: AnyObject {
    func openReceive(walletModel: WalletModel)
    func openBuyCryptoIfPossible(for walletModel: WalletModel, with userWalletModel: UserWalletModel)
    func openExchange(for walletModel: WalletModel, with userWalletModel: UserWalletModel)
    func openOnramp(for walletModel: WalletModel, with userWalletModel: UserWalletModel)
}
