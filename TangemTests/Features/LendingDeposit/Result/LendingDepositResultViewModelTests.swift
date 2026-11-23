//
//  LendingDepositResultViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
@testable import BlockchainSdk
@testable import Tangem

@Suite("Lending deposit result")
final class LendingDepositResultViewModelTests: LeakTrackingTestSuite {
    @Test("Shows the deposited amount as the confirm screen did, with no padding or cut fractions", arguments: [
        ("0.5", "ETH\u{00A0}0.5"),
        ("0.123456789", "ETH\u{00A0}0.123456789"),
    ])
    func amount(deposited: String, shown: String) throws {
        let (sut, _) = try makeSUT(amount: #require(Decimal(string: deposited)))

        #expect(sut.state.amount == shown)
    }

    @Test("Shows the account the deposit came from and the current APY")
    func state() {
        let (sut, _) = makeSUT(amount: Decimal(5) / 10)

        #expect(sut.state.currencySymbol == "ETH")
        #expect(sut.state.sourceName == "Test")
        #expect(sut.state.currentApy == "5.5%")
    }

    @Test("Go to token and Go to yield open their own destinations")
    func destinations() {
        let (sut, router) = makeSUT(amount: 1)

        sut.handle(.toToken)
        sut.handle(.toYield)

        #expect(router.opened == [.token, .yield])
    }
}

// MARK: - Helpers

private extension LendingDepositResultViewModelTests {
    func makeSUT(amount: Decimal) -> (LendingDepositResultViewModel, LendingDepositResultRouterSpy) {
        let router = trackForMemoryLeaks(LendingDepositResultRouterSpy())
        let sut = LendingDepositResultViewModel(
            sourceToken: SendSourceTokenStub(blockchain: .ethereum(testnet: false)),
            amount: amount,
            currentApy: "5.5%",
            router: router
        )

        return (trackForMemoryLeaks(sut), router)
    }
}

private final class LendingDepositResultRouterSpy: LendingDepositResultRoutable {
    enum Destination {
        case token
        case yield
    }

    private(set) var opened: [Destination] = []

    func openToken() {
        opened.append(.token)
    }

    func openYield() {
        opened.append(.yield)
    }
}
