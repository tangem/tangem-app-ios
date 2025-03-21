//
//  SwapTokenSelectorStrings.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct SwapTokenSelectorStrings: TokenSelectorLocalizable {
    let availableTokensListTitle = Localization.tokensListAvailableToSwapHeader
    var unavailableTokensListTitle: String {
        if let tokenName {
            Localization.tokensListUnavailableToSwapHeader(tokenName)
        } else {
            Localization.tokensListUnavailableToSwapSourceHeader
        }
    }

    let emptySearchMessage = Localization.actionButtonsSwapEmptySearchMessage
    let emptyTokensMessage: String? = nil
    var tokenName: String? = nil
}
