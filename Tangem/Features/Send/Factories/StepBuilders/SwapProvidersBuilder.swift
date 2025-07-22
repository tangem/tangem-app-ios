//
//  SendSwapProvidersBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct SendSwapProvidersBuilder {
    typealias IO = (input: SendSwapProvidersInput, output: SendSwapProvidersOutput)
    typealias ReturnValue = SendSwapProvidersSelectorViewModel

    let tokenItem: TokenItem
    let builder: SendDependenciesBuilder

    func makeSwapProviders(io: IO, receiveTokenInput: SendReceiveTokenInput, analyticsLogger: any SendSwapProvidersAnalyticsLogger) -> ReturnValue {
        let providersSelector = SendSwapProvidersSelectorViewModel(
            input: io.input,
            output: io.output,
            receiveTokenInput: receiveTokenInput,
            tokenItem: tokenItem,
            expressProviderFormatter: builder.makeExpressProviderFormatter(),
            priceChangeFormatter: builder.makePriceChangeFormatter(),
            analyticsLogger: analyticsLogger
        )

        return providersSelector
    }
}
