//
//  EarnSearchMatcherTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Testing
@testable import Tangem

@Suite("EarnSearchMatcher Tests")
struct EarnSearchMatcherTests {
    private let matcher = EarnSearchMatcher()

    @Test("Blank query matches nothing")
    func blankQueryMatchesNothing() {
        let tokens = [make(name: "Solana", symbol: "SOL")]

        #expect(matcher.match(tokens, query: "").isEmpty)
        #expect(matcher.match(tokens, query: "   ").isEmpty)
    }

    @Test("Matches the name and the symbol, case insensitively")
    func matchesNameAndSymbol() {
        let solana = make(name: "Solana", symbol: "SOL")
        let cosmos = make(name: "Cosmos", symbol: "ATOM")

        #expect(matcher.match([solana, cosmos], query: "sol") == [solana])
        #expect(matcher.match([solana, cosmos], query: "COSM") == [cosmos])
        #expect(matcher.match([solana, cosmos], query: "tom") == [cosmos])
        #expect(matcher.match([solana, cosmos], query: "doge").isEmpty)
    }

    @Test("An exact symbol wins over a higher yield")
    func exactSymbolOutranksYield() {
        let ethena = make(name: "Ethena", symbol: "ENA", rateValue: 0.3)
        let ethereum = make(name: "Ethereum", symbol: "ETH", rateValue: 0.03)

        #expect(matcher.match([ethena, ethereum], query: "eth") == [ethereum, ethena])
    }

    @Test("A symbol prefix outranks a name prefix, which outranks a substring")
    func prefixesOutrankSubstrings() {
        let symbolPrefix = make(name: "Wrapped Bitcoin", symbol: "BTCB")
        let namePrefix = make(name: "BTC Yield Vault", symbol: "BYV")
        let substring = make(name: "Stacks", symbol: "XBTC")

        let matches = matcher.match([substring, namePrefix, symbolPrefix], query: "btc")

        #expect(matches == [symbolPrefix, namePrefix, substring])
    }

    @Test("Equally relevant matches are ordered by yield, then by name")
    func equalRelevanceFallsBackToYieldAndName() {
        let solana = make(name: "Solana", symbol: "SLN", rateValue: 0.08)
        let solace = make(name: "Solace", symbol: "SLC", rateValue: 0.08)
        let solar = make(name: "Solar", symbol: "SLR", rateValue: 0.01)

        let matches = matcher.match([solar, solana, solace], query: "sol")

        #expect(matches == [solace, solana, solar])
    }

    @Test("Both opportunities of the same token stay in the results")
    func keepsStakingAndYieldOfTheSameToken() {
        let staking = make(name: "Ethereum", symbol: "ETH", earnType: .staking)
        let yield = make(name: "Ethereum", symbol: "ETH", earnType: .yieldMode)

        #expect(matcher.match([staking, yield], query: "eth").count == 2)
    }
}

// MARK: - Fixtures

private extension EarnSearchMatcherTests {
    func make(
        name: String,
        symbol: String,
        networkId: String = "ethereum",
        rateValue: Decimal = 0.05,
        earnType: EarnType = .staking
    ) -> EarnTokenModel {
        EarnTokenModel(
            id: name.lowercased(),
            name: name,
            symbol: symbol,
            imageUrl: nil,
            networkId: networkId,
            networkName: networkId.capitalized,
            blockchainIconAsset: nil,
            contractAddress: nil,
            decimalCount: nil,
            rateValue: rateValue,
            rateType: .apy,
            rateText: "",
            earnType: earnType
        )
    }
}
