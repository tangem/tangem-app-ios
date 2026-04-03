//
//  ActionButtonsSellRootRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsSellFlowRoutable: AnyObject {
    func openSell(userWalletModel: some UserWalletModel, tokenSelectorViewModel: TokenSelectorViewModel)
}
