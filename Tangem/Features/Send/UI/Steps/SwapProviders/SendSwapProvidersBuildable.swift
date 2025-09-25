//
//  SendSwapProvidersBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendSwapProvidersBuildable {
    var swapProvidersIO: SendSwapProvidersBuilder2.IO { get }
    var swapProvidersTypes: SendSwapProvidersBuilder2.Types { get }
    var swapProvidersDependencies: SendSwapProvidersBuilder2.Dependencies { get }
}

extension SendSwapProvidersBuildable {
    func makeSwapProviders() -> SendSwapProvidersBuilder2.ReturnValue {
        SendSwapProvidersBuilder2.make(
            io: swapProvidersIO,
            types: swapProvidersTypes,
            dependencies: swapProvidersDependencies
        )
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
