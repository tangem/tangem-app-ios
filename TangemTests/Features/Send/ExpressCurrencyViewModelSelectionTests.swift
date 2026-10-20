//
//  ExpressCurrencyViewModelSelectionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("ExpressCurrencyViewModel token selection")
@MainActor
struct ExpressCurrencyViewModelSelectionTests {
    @Test("A selectable side becomes tappable once its token has loaded")
    func selectableSideOpensAfterTheTokenLoads() {
        let viewModel = makeSUT(isTokenSelectionEnabled: true)

        viewModel.update(wallet: .loading)
        #expect(viewModel.state.canChangeCurrency == false)

        viewModel.update(wallet: .success(makeToken()))
        #expect(viewModel.state.canChangeCurrency)
    }

    @Test("A pinned side stays untappable after its token has loaded, so the selector can never open")
    func pinnedSideStaysClosedAfterTheTokenLoads() {
        let viewModel = makeSUT(isTokenSelectionEnabled: false)

        viewModel.update(wallet: .success(makeToken()))

        #expect(viewModel.state.canChangeCurrency == false)
    }
}

// MARK: - Fixtures

private extension ExpressCurrencyViewModelSelectionTests {
    func makeSUT(isTokenSelectionEnabled: Bool) -> ExpressCurrencyViewModel {
        ExpressCurrencyViewModel(
            viewType: .send,
            headerType: .action(name: "From"),
            isTokenSelectionEnabled: isTokenSelectionEnabled,
            canChangeCurrency: false
        )
    }

    func makeToken() -> SwapableTokenStub {
        SwapableTokenStub(tokenItem: .accountToken(symbol: "USDC", contract: "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"))
    }
}
