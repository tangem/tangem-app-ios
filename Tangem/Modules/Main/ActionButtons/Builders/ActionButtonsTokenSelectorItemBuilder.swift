//
//  ActionButtonsTokenSelectorItemBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct ActionButtonsTokenSelectorItemBuilder: TokenSelectorItemBuilder {
    func map(from walletModel: WalletModel, isDisabled: Bool) -> ActionButtonsTokenSelectorItem {
        let tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        let infoProvider = DefaultTokenItemInfoProvider(walletModel: walletModel)

        // [REDACTED_TODO_COMMENT]
        // from `DefaultTokenItemInfoProvider` or DefaultTokenItemInfoProvider
        // to support balance state changes loading / loaded / cached
        return ActionButtonsTokenSelectorItem(
            id: walletModel.id,
            isDisabled: isDisabled,
            tokenIconInfo: tokenIconInfo,
            infoProvider: infoProvider,
            walletModel: walletModel
        )
    }
}
