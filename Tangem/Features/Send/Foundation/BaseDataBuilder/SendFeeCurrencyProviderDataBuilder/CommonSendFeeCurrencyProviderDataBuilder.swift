//
//  CommonSendFeeCurrencyProviderDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CommonSendFeeCurrencyProviderDataBuilder: SendFeeCurrencyProviderDataBuilder {
    let sourceTokenInput: SendSourceTokenInput

    func makeFeeCurrencyData() throws -> FeeCurrencyNavigatingDismissOption {
        let sourceToken = try sourceTokenInput.sourceToken.get()
        return .init(userWalletId: sourceToken.userWalletInfo.id, tokenItem: sourceToken.feeTokenItem)
    }
}
