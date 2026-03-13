//
//  ActionButtonsBuyFlowRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsBuyFlowRoutable: AnyObject {
    /// Used for accounts-aware buy flow
    func openBuy(userWalletModels: [UserWalletModel])
}
