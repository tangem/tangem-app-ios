//
//  SendSwapProvidersBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct SendSwapProvidersBuilder {
    typealias IO = (input: SendSwapProvidersInput, output: SendSwapProvidersOutput)
    typealias ReturnValue = (providersSelector: SendSwapProvidersSelectorViewModel, finish: SendSwapProviderFinishViewModel)

    let tokenItem: TokenItem
    let builder: SendDependenciesBuilder

    func makeSwapProviders(
        io: IO,
        receiveTokenInput: SendReceiveTokenInput
    ) -> ReturnValue {
        let providersSelector = SendSwapProvidersSelectorViewModel(
            input: io.input,
            output: io.output,
            receiveTokenInput: receiveTokenInput,
            tokenItem: tokenItem,
            expressProviderFormatter: builder.makeExpressProviderFormatter(),
            priceChangeFormatter: builder.makePriceChangeFormatter()
        )

        let finish = makeSendSwapProviderFinishViewModel(input: io.input)

        return (providersSelector: providersSelector, finish: finish)
    }

    func makeSendSwapProviderFinishViewModel(input: SendSwapProvidersInput) -> SendSwapProviderFinishViewModel {
        SendSwapProviderFinishViewModel(tokenItem: tokenItem, input: input)
    }
}
