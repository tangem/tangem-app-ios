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

enum SendSwapProvidersBuilder2 {
    struct IO {
        let input: SendSwapProvidersInput
        let output: SendSwapProvidersOutput
        let receiveTokenInput: SendReceiveTokenInput
    }

    struct Types {
        let tokenItem: TokenItem
    }

    struct Dependencies {
        let analyticsLogger: any SendSwapProvidersAnalyticsLogger
        let expressProviderFormatter: ExpressProviderFormatter
        let priceChangeFormatter: PriceChangeFormatter
    }

    typealias ReturnValue = SendSwapProvidersSelectorViewModel

    static func make(io: IO, types: Types, dependencies: Dependencies) -> ReturnValue {
        let providersSelector = SendSwapProvidersSelectorViewModel(
            input: io.input,
            output: io.output,
            receiveTokenInput: io.receiveTokenInput,
            tokenItem: types.tokenItem,
            expressProviderFormatter: dependencies.expressProviderFormatter,
            priceChangeFormatter: dependencies.priceChangeFormatter,
            analyticsLogger: dependencies.analyticsLogger
        )

        return providersSelector
    }
}
