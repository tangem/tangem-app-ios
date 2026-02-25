//
//  EmptySendFeeCurrencyProviderDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct EmptySendFeeCurrencyProviderDataBuilder: SendFeeCurrencyProviderDataBuilder {
    func makeFeeCurrencyData() throws -> FeeCurrencyNavigatingDismissOption {
        throw SendFeeCurrencyProviderDataBuilderError.notSupported
    }
}
