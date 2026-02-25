//
//  CommonSendFeeCurrencyProviderDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CommonSendFeeCurrencyProviderDataBuilder: SendFeeCurrencyProviderDataBuilder {
    let sourceToken: SendSourceToken

    func makeFeeCurrencyData() throws -> FeeCurrencyNavigatingDismissOption {
        .init(userWalletId: sourceToken.userWalletInfo.id, tokenItem: sourceToken.feeTokenItem)
    }
}
