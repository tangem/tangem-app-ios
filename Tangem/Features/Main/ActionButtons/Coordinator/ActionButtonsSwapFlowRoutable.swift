//
//  ActionButtonsSwapRootRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol ActionButtonsSwapFlowRoutable: AnyObject {
    // [REDACTED_TODO_COMMENT]
    func openSwap(userWalletModel: some UserWalletModel, tokenSelectorViewModel: TokenSelectorViewModel)
    func openSwap(predefinedParameters: PredefinedSwapParameters)
}
