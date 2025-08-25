//
//  MarketsPortfolioContainerRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsPortfolioContainerRoutable: AnyObject {
    func openReceive(walletModel: any WalletModel)
    func openBuyCryptoIfPossible(for walletModel: any WalletModel, with userWalletModel: UserWalletModel)
    func openExchange(for walletModel: any WalletModel, with userWalletModel: UserWalletModel)
    func openOnramp(for walletModel: any WalletModel, with userWalletModel: UserWalletModel)
    func openStaking(for walletModel: any WalletModel, with userWalletModel: UserWalletModel)
}
