//
//  SwapSlippageStateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemExpress
@testable import Tangem

@Suite("SwapSlippageState")
struct SwapSlippageStateTests {
    private let pair = SwapSlippageState.Pair(
        source: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
        receive: .blockchain(.init(.polygon(testnet: false), derivationPath: nil))
    )

    @Test("A reset falls back to Auto and raises the highlight until the next confirmation, even of Auto")
    func resetHighlightsUntilConfirmed() {
        let sut = SwapSlippageState()
        var resets: [Bool] = []
        let cancellable = sut.isResetPublisher.sink { resets.append($0) }

        withExtendedLifetime(cancellable) {
            sut.set(.custom(Decimal(string: "0.005")!), for: pair)
            sut.reset()
            #expect(!sut.set(.auto, for: pair))
        }

        #expect(sut.slippage == .auto)
        #expect(resets == [false, false, true, false])
    }

    @Test("Setting the current value reports no change")
    func settingSameValueReportsNoChange() {
        let sut = SwapSlippageState()

        #expect(sut.set(.custom(Decimal(string: "0.005")!), for: pair))
        #expect(!sut.set(.custom(Decimal(string: "0.005")!), for: pair))
    }

    @Test("Auto never asks for a reset")
    func autoNeverResets() {
        let sut = SwapSlippageState()

        #expect(!sut.shouldReset(for: makeState(isCustomSlippageSupported: false), pair: nil))
    }

    @Test("A custom slippage resets once its pair no longer matches")
    func pairChangeResets() {
        let sut = SwapSlippageState()
        sut.set(.custom(Decimal(string: "0.003")!), for: pair)
        let otherPair = SwapSlippageState.Pair(source: pair.receive, receive: pair.source)

        #expect(!sut.shouldReset(for: makeState(), pair: pair))
        #expect(sut.shouldReset(for: makeState(), pair: otherPair))
    }

    @Test(
        "A custom slippage resets for a provider that does not support it or would reject the value",
        arguments: [
            (isSupported: true, defaultSlippage: Decimal(string: "0.003")!, shouldReset: false),
            (isSupported: true, defaultSlippage: Decimal(string: "0.0015")!, shouldReset: true),
            (isSupported: false, defaultSlippage: Decimal(string: "0.003")!, shouldReset: true),
        ]
    )
    func providerDecidesReset(isSupported: Bool, defaultSlippage: Decimal, shouldReset: Bool) {
        let sut = SwapSlippageState()
        sut.set(.custom(Decimal(string: "0.0035")!), for: pair)

        let state = makeState(defaultSlippage: defaultSlippage, isCustomSlippageSupported: isSupported)

        #expect(sut.shouldReset(for: state, pair: pair) == shouldReset)
    }

    @Test("A custom slippage is kept while no swap provider is selected")
    func keptWithoutSelectedProvider() {
        let sut = SwapSlippageState()
        sut.set(.custom(Decimal(string: "0.0035")!), for: pair)

        #expect(!sut.shouldReset(for: .swap(selected: nil, providers: .empty), pair: pair))
        #expect(!sut.shouldReset(for: .idle, pair: pair))
    }
}

// MARK: - Helpers

private extension SwapSlippageStateTests {
    func makeState(defaultSlippage: Decimal = Decimal(string: "0.003")!, isCustomSlippageSupported: Bool = true) -> ExpressManagerState {
        let provider = ExpressAvailableProviderFixture.make(
            state: .idle,
            slippage: defaultSlippage,
            isCustomSlippageSupported: isCustomSlippageSupported
        )

        return .swap(selected: provider, providers: .empty)
    }
}
