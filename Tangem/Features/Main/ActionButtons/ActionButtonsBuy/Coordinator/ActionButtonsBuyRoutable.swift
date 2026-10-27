//
//  ActionButtonsBuyRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonsBuyRoutable: AnyObject {
    func openAddFunds(userWalletInfo: UserWalletInfo, walletModel: any WalletModel)

    func dismiss()
}
