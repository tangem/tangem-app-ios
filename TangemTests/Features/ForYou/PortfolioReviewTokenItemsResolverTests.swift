//
//  PortfolioReviewTokenItemsResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("PortfolioReviewTokenItemsResolver")
struct PortfolioReviewTokenItemsResolverTests {
    typealias SUT = PortfolioReviewTokenItemsResolver

    private static let ethereumNetwork = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)

    private let bitcoin = TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))
    private let litecoin = TokenItem.blockchain(.init(.litecoin, derivationPath: nil))
    private let ethereum = TokenItem.blockchain(ethereumNetwork)
    private let usdt = TokenItem.token(
        Token(name: "Tether", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6),
        ethereumNetwork
    )

    @Test("A stored token whose network has no derivation stays in the list")
    func keepsUnderivedToken() {
        expectResolve(stored: [litecoin], walletModels: [], equals: [.withoutDerivation(litecoin)])
    }

    @Test("A stored token with a derived network is paired with its wallet model")
    func pairsDerivedToken() {
        let model = makeWalletModel(for: bitcoin)

        expectResolve(stored: [bitcoin], walletModels: [model], equals: [.default(model)])
    }

    @Test("A partially derived wallet keeps both kinds in the stored order")
    func keepsBothKindsInStoredOrder() {
        let bitcoinModel = makeWalletModel(for: bitcoin)
        let ethereumModel = makeWalletModel(for: ethereum)

        expectResolve(
            stored: [bitcoin, litecoin, ethereum],
            walletModels: [bitcoinModel, ethereumModel],
            equals: [.default(bitcoinModel), .withoutDerivation(litecoin), .default(ethereumModel)]
        )
    }

    /// Mirrors the main screen: with the network derived, the entry is dropped rather than mislabelled as addressless.
    @Test("A token on a derived network without its own wallet model is dropped")
    func dropsTokenWithoutModelOnDerivedNetwork() {
        let ethereumModel = makeWalletModel(for: ethereum)

        expectResolve(stored: [ethereum, usdt], walletModels: [ethereumModel], equals: [.default(ethereumModel)])
    }

    @Test("An empty stored list yields nothing even when wallet models exist")
    func emptyStoredList() {
        expectResolve(stored: [], walletModels: [makeWalletModel(for: bitcoin)], equals: [])
    }
}

// MARK: - Assertions

private extension PortfolioReviewTokenItemsResolverTests {
    func expectResolve(
        stored: [TokenItem],
        walletModels: [any WalletModel],
        equals expected: [TokenItemType],
        sourceLocation: SourceLocation = .init(fileID: #fileID, filePath: #filePath, line: #line, column: #column)
    ) {
        let resolved = SUT.resolve(userTokens: stored, walletModels: walletModels)

        #expect(resolved == expected, sourceLocation: sourceLocation)
    }
}

// MARK: - Fixtures

private extension PortfolioReviewTokenItemsResolverTests {
    func makeWalletModel(for tokenItem: TokenItem) -> any WalletModel {
        WalletModelTestsMock(tokenItem: tokenItem, isEmpty: false)
    }
}
