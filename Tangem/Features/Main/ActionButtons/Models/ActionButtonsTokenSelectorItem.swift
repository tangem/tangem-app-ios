//
//  ActionButtonsTokenSelectorItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct ActionButtonsTokenSelectorItem: Identifiable {
    let id: String
    let isDisabled: Bool
    let tokenIconInfo: TokenIconInfo
    let infoProvider: DefaultTokenItemInfoProvider
    let walletModel: any WalletModel
}

extension ActionButtonsTokenSelectorItem: Equatable {
    static func == (lhs: ActionButtonsTokenSelectorItem, rhs: ActionButtonsTokenSelectorItem) -> Bool {
        lhs.id == rhs.id
            && lhs.isDisabled == rhs.isDisabled
            && lhs.tokenIconInfo == rhs.tokenIconInfo
            && lhs.infoProvider.id == rhs.infoProvider.id
            && lhs.walletModel.id == rhs.walletModel.id
    }
}
