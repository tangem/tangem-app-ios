//
//  SendSwapProvidersBuildable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol SendSwapProvidersBuildable {
    var swapProvidersIO: SendSwapProvidersBuilder.IO { get }
    var swapProvidersTypes: SendSwapProvidersBuilder.Types { get }
    var swapProvidersDependencies: SendSwapProvidersBuilder.Dependencies { get }
}

extension SendSwapProvidersBuildable {
    func makeSwapProviders(router: SendSwapProvidersRoutable) -> SendSwapProvidersBuilder.ReturnValue {
        SendSwapProvidersBuilder.make(
            io: swapProvidersIO,
            types: swapProvidersTypes,
            dependencies: swapProvidersDependencies,
            router: router
        )
    }
}

enum SendSwapProvidersBuilder {
    struct IO {
        let input: SendSwapProvidersInput
        let output: SendSwapProvidersOutput
        let approveInput: SwapApproveInput
        let approveOutput: SwapApproveOutput
        let sourceTokenInput: SendSourceTokenInput
        let receiveTokenInput: SendReceiveTokenInput
        let receiveTokenAmountInput: SendReceiveTokenAmountInput?
    }

    struct Types {
        let tokenItem: TokenItem
    }

    struct Dependencies {
        let analyticsLogger: any SendSwapProvidersAnalyticsLogger
        let expressProviderFormatter: ExpressProviderFormatter
        let priceChangeFormatter: PriceChangeFormatter
    }

    typealias ReturnValue = (selector: SendSwapProvidersSelectorViewModel, compact: SwapSummaryProviderViewModel)

    static func make(io: IO, types: Types, dependencies: Dependencies, router: SendSwapProvidersRoutable) -> ReturnValue {
        let providersSelector = SendSwapProvidersSelectorViewModel(
            input: io.input,
            output: io.output,
            router: router,
            approveInput: io.approveInput,
            approveOutput: io.approveOutput,
            receiveTokenInput: io.receiveTokenInput,
            receiveTokenAmountInput: io.receiveTokenAmountInput,
            tokenItem: types.tokenItem,
            expressProviderFormatter: dependencies.expressProviderFormatter,
            priceChangeFormatter: dependencies.priceChangeFormatter,
            analyticsLogger: dependencies.analyticsLogger
        )

        let swapSummaryProviderViewModel = SwapSummaryProviderViewModel(
            expressProviderFormatter: .init(),
            sourceTokenInput: io.sourceTokenInput,
            receiveTokenInput: io.receiveTokenInput,
            swapProvidersInput: io.input,
            receiveTokenAmountInput: io.receiveTokenAmountInput
        )

        return (selector: providersSelector, compact: swapSummaryProviderViewModel)
    }
}
