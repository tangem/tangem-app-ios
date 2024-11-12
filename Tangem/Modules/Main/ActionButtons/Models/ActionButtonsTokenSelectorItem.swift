//
//  ActionButtonsTokenSelectorItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct ActionButtonsTokenSelectorItem: Identifiable, Equatable {
    let id: Int
    let tokenIconInfo: TokenIconInfo
    let name: String
    let symbol: String
    let balance: String
    let fiatBalance: String
    let isDisabled: Bool
    let amountType: Amount.AmountType
    let blockchain: Blockchain
    let defaultAddress: String
}
