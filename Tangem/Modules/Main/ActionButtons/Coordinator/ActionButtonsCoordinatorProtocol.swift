//
//  ActionButtonsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ActionButtonsRoutable {
    func openBuy(userWalletModel: UserWalletModel)
    func openSwap()
    func openSell()
}
