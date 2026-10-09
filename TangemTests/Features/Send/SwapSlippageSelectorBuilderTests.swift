//
//  SwapSlippageSelectorBuilderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemExpress
import TangemFoundation
@testable import Tangem

@Suite("SwapSlippageSelectorBuilder")
@MainActor
struct SwapSlippageSelectorBuilderTests {
    @Test("Reports the opening once when a provider is selected")
    func reportsOpening() {
        let output = SlippageOutputSpy()
        let provider = ExpressAvailableProviderFixture.make(state: .idle, slippage: Decimal(string: "0.003"), isCustomSlippageSupported: true)
        let builder = makeBuilder(provider: provider.provider, output: output)

        let viewModel = builder.makeSlippageSelector()

        #expect(viewModel != nil)
        #expect(output.openingsCount == 1)
    }

    @Test("Opens nothing and reports nothing until a provider has loaded")
    func skipsWithoutProvider() {
        let output = SlippageOutputSpy()
        let builder = makeBuilder(provider: nil, output: output)

        let viewModel = builder.makeSlippageSelector()

        #expect(viewModel == nil)
        #expect(output.openingsCount == 0)
    }
}

// MARK: - Helpers

private extension SwapSlippageSelectorBuilderTests {
    func makeBuilder(provider: ExpressProvider?, output: SlippageOutputSpy) -> SwapSlippageSelectorBuilder {
        SwapSlippageSelectorBuilder(slippageInput: SlippageInputStub(provider: provider), slippageOutput: output)
    }
}

private final class SlippageOutputSpy: SwapSlippageOutput {
    private(set) var openingsCount = 0

    func userDidOpenSlippageSelector() {
        openingsCount += 1
    }

    func userDidSet(slippage: SwapSlippage) {}
}

private final class SlippageInputStub: SwapSlippageInput {
    let slippageProvider: ExpressProvider?

    init(provider: ExpressProvider?) {
        slippageProvider = provider
    }

    var slippage: SwapSlippage { .auto }
    var slippagePublisher: AnyPublisher<SwapSlippage, Never> { Just(.auto).eraseToAnyPublisher() }
    var slippageProviderPublisher: AnyPublisher<ExpressProvider?, Never> { Just(slippageProvider).eraseToAnyPublisher() }
    var isCustomSlippageResetPublisher: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }
}
