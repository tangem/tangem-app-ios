//
//  ActionButtonsBuyFlowRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol ActionButtonsBuyFlowRoutable: AnyObject {
    func openBuy(userWalletModels: [UserWalletModel], preferredWalletId: UserWalletId?)
}
