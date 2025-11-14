//
//  PendingExpressTxStatusRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PendingExpressTxStatusRoutable: AnyObject {
    func openURL(_ url: URL)
    func openRefundCurrency(walletModel: any WalletModel, userWalletModel: UserWalletModel)
    func dismissPendingTxSheet()
}
