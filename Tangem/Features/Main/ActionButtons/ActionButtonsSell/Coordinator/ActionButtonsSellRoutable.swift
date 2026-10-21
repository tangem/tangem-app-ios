//
//  ActionButtonsSellRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonsSellRoutable: AnyObject {
    func openTransfer(walletModel: any WalletModel, userWalletInfo: UserWalletInfo)
    func dismiss()
}
