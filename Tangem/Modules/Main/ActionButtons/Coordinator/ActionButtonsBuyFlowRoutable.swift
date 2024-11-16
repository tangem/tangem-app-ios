//
//  ActionButtonsBuyFlowRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsBuyFlowRoutable {
    func openBuy(userWalletModel: some UserWalletModel)
    func openP2PTutorial()
    func openBankWarning(confirmCallback: @escaping () -> Void, declineCallback: @escaping () -> Void)
}
