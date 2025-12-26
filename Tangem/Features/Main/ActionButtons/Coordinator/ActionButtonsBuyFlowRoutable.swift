//
//  ActionButtonsBuyFlowRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsBuyFlowRoutable: AnyObject {
    // [REDACTED_TODO_COMMENT]
    func openBuy(userWalletModel: some UserWalletModel)

    /// Used for accounts-aware buy flow
    func openBuy(userWalletModels: [UserWalletModel])
}
