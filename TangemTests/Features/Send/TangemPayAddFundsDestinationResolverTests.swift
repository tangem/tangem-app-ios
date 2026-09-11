//
//  TangemPayAddFundsDestinationResolverTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("TangemPayAddFundsDestinationResolver")
struct TangemPayAddFundsDestinationResolverTests {
    private let usdtBase = SwapableTokenStub(
        tokenItem: .accountToken(symbol: "USDT", contract: "0xBASEUSDT", blockchain: .base(testnet: false))
    )
    private let usdtPolygon = SwapableTokenStub(tokenItem: .accountToken(symbol: "USDT", contract: "0xUSDT"))
    private let usdcPolygon = SwapableTokenStub(tokenItem: .accountToken(symbol: "USDC", contract: "0xUSDC"))
    /// Lives in a network of its own, so every test can tell the default apart from any candidate.
    private let defaultDestination = SwapableTokenStub(
        tokenItem: .accountToken(symbol: "USDC", contract: "0xETHUSDC", blockchain: .ethereum(testnet: false))
    )

    private var resolver: TangemPayAddFundsDestinationResolver {
        TangemPayAddFundsDestinationResolver(
            candidates: [usdtBase, usdtPolygon, usdcPolygon],
            defaultDestination: defaultDestination
        )
    }

    @Test("A currency match wins — the pair becomes a plain transfer")
    func currencyMatchWins() {
        let source = SwapableTokenStub(tokenItem: .accountToken(symbol: "USDT", contract: "0xUSDT"))

        #expect(resolver.resolveDestination(for: source).tokenItem == usdtPolygon.tokenItem)
    }

    @Test("One contract spelled with two symbols is still one asset — the pair stays a transfer")
    func symbolMismatchOnTheSameContractStaysTransfer() {
        let source = SwapableTokenStub(tokenItem: .accountToken(symbol: "USDT0", contract: "0xUSDT"))

        #expect(resolver.resolveDestination(for: source).tokenItem == usdtPolygon.tokenItem)
    }

    @Test("A checksum-casing mismatch degrades to an in-network swap rather than a false transfer")
    func contractCasingMismatchDegradesToInNetworkSwap() {
        // Express's transfer detection compares contracts exactly, so this can't be a transfer;
        // routing to the same-cased-differently token would make a degenerate token-into-itself swap.
        let source = SwapableTokenStub(tokenItem: .accountToken(symbol: "USDT", contract: "0xusdt"))

        #expect(resolver.resolveDestination(for: source).tokenItem == usdcPolygon.tokenItem)
    }

    @Test("A token the account doesn't hold swaps to an account token in the same network")
    func sameNetworkTokenSwapsWithinNetwork() {
        let source = SwapableTokenStub(tokenItem: .accountToken(symbol: "DAI", contract: "0xDAI"))

        #expect(resolver.resolveDestination(for: source).tokenItem == usdtPolygon.tokenItem)
    }

    @Test("A foreign-network source falls back to the first candidate")
    func foreignNetworkFallsBackToFirstCandidate() {
        let source = SwapableTokenStub(blockchain: .ethereum(testnet: false))

        #expect(resolver.resolveDestination(for: source).tokenItem == usdtBase.tokenItem)
    }

    @Test("The default remains only when every candidate is the source's own asset")
    func defaultOnlyWhenNoCandidateDiffers() {
        let resolver = TangemPayAddFundsDestinationResolver(
            candidates: [usdcPolygon],
            defaultDestination: defaultDestination
        )

        // A user-saved variant of the only candidate: the decimals differ, so the currency
        // check fails while the asset is the same.
        let source = SwapableTokenStub(
            tokenItem: .accountToken(symbol: "USDC", contract: "0xUSDC", decimalCount: 18)
        )

        #expect(resolver.resolveDestination(for: source).tokenItem == defaultDestination.tokenItem)
    }

    @Test("A same-asset default is skipped for any other candidate — never a token-into-itself pair")
    func sameAssetDefaultYieldsAnotherCandidate() {
        let baseUSDC = SwapableTokenStub(
            tokenItem: .accountToken(symbol: "USDC", contract: "0xBASEUSDC", blockchain: .base(testnet: false))
        )
        let resolver = TangemPayAddFundsDestinationResolver(
            candidates: [usdcPolygon, baseUSDC],
            defaultDestination: usdcPolygon
        )

        let source = SwapableTokenStub(
            tokenItem: .accountToken(symbol: "USDC", contract: "0xUSDC", decimalCount: 18)
        )

        #expect(resolver.resolveDestination(for: source).tokenItem == baseUSDC.tokenItem)
    }

    @Test("Contract identity folds case on every network, matching the domain's Token equality")
    func contractIdentityFoldsCaseForAllNetworks() {
        let tronUSDT = SwapableTokenStub(tokenItem: .tronToken(symbol: "USDT", contract: "TUsdtContract"))
        let resolver = TangemPayAddFundsDestinationResolver(
            candidates: [tronUSDT],
            defaultDestination: usdcPolygon
        )

        // `Token.==` lowercases contracts for every network, so a case-differing Tron contract is
        // one token in the app model — routing into it would make a token-into-itself swap.
        let source = SwapableTokenStub(tokenItem: .tronToken(symbol: "XYZ", contract: "tusdtcontract"))

        #expect(resolver.resolveDestination(for: source).tokenItem == usdcPolygon.tokenItem)
    }
}
