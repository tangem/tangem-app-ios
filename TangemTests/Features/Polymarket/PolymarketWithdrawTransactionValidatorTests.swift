//
//  PolymarketWithdrawTransactionValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket withdraw amount validation", .timeLimit(.minutes(1)))
struct PolymarketWithdrawTransactionValidatorTests {
    @Test("An amount above the available balance is refused")
    func refusesAnAmountAboveTheBalance() async throws {
        try await withUSDCQuote {
            let sut = makeSUT()

            #expect(throws: ValidationError.amountExceedsBalance) {
                try sut.validate(amount: makeAmount(Self.balance + Self.smallestUnit))
            }
        }
    }

    @Test("The whole available balance may be withdrawn")
    func acceptsTheWholeBalance() async throws {
        try await withUSDCQuote {
            let sut = makeSUT()

            #expect(throws: Never.self) {
                try sut.validate(amount: makeAmount(Self.balance))
            }
        }
    }

    @Test("An amount a token unit short of the minimum in dollars is refused, and the refusal names that minimum in tokens")
    func refusesAnAmountJustUnderTheMinimum() async throws {
        try await withUSDCQuote {
            let sut = makeSUT()

            #expect(throws: ValidationError.minimumRestrictAmount(amount: makeAmount(Self.minimumInToken))) {
                try sut.validate(amount: makeAmount(Self.minimumInToken - Self.smallestUnit))
            }
        }
    }

    @Test("An amount exactly at the minimum, converted to tokens and rounded up, is accepted")
    func acceptsTheMinimum() async throws {
        try await withUSDCQuote {
            let sut = makeSUT()

            #expect(throws: Never.self) {
                try sut.validate(amount: makeAmount(Self.minimumInToken))
            }
        }
    }
}

// MARK: - Helpers

private extension PolymarketWithdrawTransactionValidatorTests {
    static let balance = Decimal(10)
    static let minimumUSD = Decimal(2)
    static let usdcPriceUsd = Decimal(string: "0.9998")!
    static let minimumInToken = Decimal(string: "2.000401")!
    static let smallestUnit = Decimal(string: "0.000001")!

    func makeSUT() -> PolymarketWithdrawTransactionValidator {
        PolymarketWithdrawTransactionValidator(
            availableBalanceProvider: MutableTokenBalanceProviderMock(balance: Self.balance),
            minimum: PolymarketUSDAmount(usd: Self.minimumUSD, tokenItem: PolymarketUtilities.usdcTokenItem)
        )
    }

    func makeAmount(_ value: Decimal) -> Amount {
        let tokenItem = PolymarketUtilities.usdcTokenItem

        return Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }

    func withUSDCQuote(_ operation: () throws -> Void) async throws {
        try await InjectedDependenciesIsolation.shared.run {
            let previousRepository = try #require(
                InjectedValues[\.quotesRepository] as? TokenQuotesRepository & TokenQuotesRepositoryUpdater
            )
            let currencyId = try #require(PolymarketUtilities.usdcTokenItem.currencyId)
            let quote = TokenQuote(
                currencyId: currencyId,
                price: Self.usdcPriceUsd,
                priceUsd: Self.usdcPriceUsd,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "USD"
            )

            InjectedValues.setTokenQuotesRepository(MockTokenQuotesRepository(quotes: [currencyId: quote]))
            defer { InjectedValues.setTokenQuotesRepository(previousRepository) }

            try operation()
        }
    }
}
