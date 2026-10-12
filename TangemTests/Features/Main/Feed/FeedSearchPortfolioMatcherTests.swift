//
//  FeedSearchPortfolioMatcherTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
@testable import Tangem

@Suite("FeedSearchPortfolioMatcher")
struct FeedSearchPortfolioMatcherTests {
    private let matcher = FeedSearchPortfolioMatcher()

    @Test("A blank query matches nothing, however many tokens the wallets hold")
    func blankQueryMatchesNothing() {
        let matches = matcher.matches(query: "", walletModels: Self.walletModels)

        #expect(matches.isEmpty)
    }

    @Test("A query matches the token name and the ticker, whatever the case")
    func matchesNameAndSymbol() {
        let byName = matcher.matches(query: "usd coin", walletModels: Self.walletModels)
        let bySymbol = matcher.matches(query: "USDC", walletModels: Self.walletModels)

        #expect(byName.map(\.tokenItem.currencySymbol) == ["USDC"])
        #expect(bySymbol.map(\.tokenItem.currencySymbol) == ["USDC"])
    }

    @Test("A query matches anywhere in the name, the middle of a word included")
    func matchesInsideTheName() {
        let matches = matcher.matches(query: "eth", walletModels: Self.walletModels)

        #expect(matches.map(\.tokenItem.currencySymbol) == ["ETH", "USDT"])
    }

    @Test("A query that matches no token returns nothing")
    func unknownQueryMatchesNothing() {
        let matches = matcher.matches(query: "zzz", walletModels: Self.walletModels)

        #expect(matches.isEmpty)
    }
}

// MARK: - Fixtures

private extension FeedSearchPortfolioMatcherTests {
    static let network = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)

    static var walletModels: [any WalletModel] {
        [
            WalletModelTestsMock(tokenItem: .blockchain(network), isEmpty: false),
            WalletModelTestsMock(
                tokenItem: .token(
                    Token(name: "USD Coin", symbol: "USDC", contractAddress: "0xUSDC", decimalCount: 6),
                    network
                ),
                isEmpty: false
            ),
            WalletModelTestsMock(
                tokenItem: .token(
                    Token(name: "Tether", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6),
                    network
                ),
                isEmpty: false
            ),
        ]
    }
}
