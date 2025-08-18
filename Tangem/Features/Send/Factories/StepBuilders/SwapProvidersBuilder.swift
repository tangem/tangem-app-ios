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
    let expressProviderFormatter: ExpressProviderFormatter
    let priceChangeFormatter: PriceChangeFormatter
    let analyticsLogger: any SendSwapProvidersAnalyticsLogger

    func makeSwapProviders(io: IO, receiveTokenInput: SendReceiveTokenInput) -> ReturnValue {
        let providersSelector = SendSwapProvidersSelectorViewModel(
            input: io.input,
            output: io.output,
            receiveTokenInput: receiveTokenInput,
            tokenItem: tokenItem,
            expressProviderFormatter: expressProviderFormatter,
            priceChangeFormatter: priceChangeFormatter,
            analyticsLogger: analyticsLogger
        )

        return providersSelector
    }
}
