//
//  TokenSelectorItemBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol TokenSelectorItemBuilder {
    associatedtype TokenModel

    func map(from walletModel: any WalletModel, isDisabled: Bool) -> TokenModel
}
