//
//  PolymarketDepositReceivingRestrictionsProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite
struct PolymarketDepositReceivingRestrictionsProviderTests {
    @Test("A receive amount worth less than the threshold blocks the swap")
    func belowMinimumBlocks() async throws {
        try await withProvider(priceUsd: 1) { sut in
            let belowThreshold = try await sut.restriction(expectAmount: 1.5)

            #expect(minAmount(belowThreshold) == Self.minCheckoutUSD)
        }
    }

    @Test("A receive amount at the threshold or above passes")
    func aboveMinimumPasses() async throws {
        try await withProvider(priceUsd: 1) { sut in
            let atThreshold = try await sut.restriction(expectAmount: 2)
            let aboveThreshold = try await sut.restriction(expectAmount: 2.5)

            #expect(atThreshold == nil)
            #expect(aboveThreshold == nil)
        }
    }

    @Test("The threshold is compared in the deposit token, so a pricier asset needs less of it")
    func thresholdIsComparedInTokenUnits() async throws {
        try await withProvider(priceUsd: 50) { sut in
            let atThreshold = try await sut.restriction(expectAmount: Decimal(4) / 100)
            let belowThreshold = try await sut.restriction(expectAmount: Decimal(39) / 1000)

            #expect(atThreshold == nil)
            #expect(minAmount(belowThreshold) == Self.minCheckoutUSD)
        }
    }

    @Test("A threshold that does not divide evenly is rounded up, never below the bridge's own minimum")
    func unevenThresholdRoundsUp() async throws {
        let expected = try #require(Decimal(string: "0.666667"))

        try await withProvider(priceUsd: 3) { sut in
            let belowThreshold = try await sut.restriction(expectAmount: 0.6)
            let atThreshold = try await sut.restriction(expectAmount: expected)

            #expect(minAmount(belowThreshold) == Self.minCheckoutUSD)
            #expect(atThreshold == nil)
        }
    }

    @Test("A zero price falls back to dollar parity instead of dropping the threshold")
    func zeroPriceFallsBackToDollarParity() async throws {
        try await withProvider(priceUsd: 0) { sut in
            let belowThreshold = try await sut.restriction(expectAmount: 0.0001)
            let atThreshold = try await sut.restriction(expectAmount: Self.minCheckoutUSD)

            #expect(minAmount(belowThreshold) == Self.minCheckoutUSD)
            #expect(atThreshold == nil)
        }
    }

    @Test("An unpriced deposit asset falls back to dollar parity, since it is a dollar stablecoin")
    func missingPriceFallsBackToDollarParity() async throws {
        try await withProvider(priceUsd: nil) { sut in
            let belowThreshold = try await sut.restriction(expectAmount: 0.0001)
            let atThreshold = try await sut.restriction(expectAmount: Self.minCheckoutUSD)

            #expect(minAmount(belowThreshold) == Self.minCheckoutUSD)
            #expect(atThreshold == nil)
        }
    }

    @Test("The zero-amount backup probe is answered with the backup, not with the threshold")
    func zeroAmountProbeReportsTheBackup() async throws {
        try await withProvider(priceUsd: 1, backupState: .incompleteBackup) { sut in
            guard case .incompleteBackup = try await sut.restriction(expectAmount: .zero) else {
                Issue.record("The zero probe must report the incomplete backup")
                return
            }
        }
    }

    @Test("A wallet without a backup is still blocked on an amount below the threshold")
    func belowMinimumOutranksTheBackup() async throws {
        try await withProvider(priceUsd: 1, backupState: .incompleteBackup) { sut in
            let belowThreshold = try await sut.restriction(expectAmount: 1.5)

            #expect(minAmount(belowThreshold) == Self.minCheckoutUSD)
        }
    }

    @Test("The ceiling is exclusive: exactly fifty thousand is already refused")
    func theCeilingItselfIsRefused() async throws {
        try await withProvider(priceUsd: 1) { sut in
            let atCeiling = try await sut.restriction(expectAmount: Self.maximumDepositUSD)
            let aboveCeiling = try await sut.restriction(expectAmount: Self.maximumDepositUSD + 1)

            #expect(maxAmount(atCeiling) == Self.maximumDepositUSD)
            #expect(maxAmount(aboveCeiling) == Self.maximumDepositUSD)
        }
    }

    @Test("A deposit just short of the ceiling passes")
    func justBelowTheCeilingPasses() async throws {
        try await withProvider(priceUsd: 1) { sut in
            let belowCeiling = try await sut.restriction(expectAmount: Self.maximumDepositUSD - 1)

            #expect(belowCeiling == nil)
        }
    }

    @Test("The ceiling is compared in the deposit token too, so a pricier asset reaches it sooner")
    func ceilingIsComparedInTokenUnits() async throws {
        try await withProvider(priceUsd: 50) { sut in
            let atCeiling = try await sut.restriction(expectAmount: Self.maximumDepositUSD / 50)
            let belowCeiling = try await sut.restriction(expectAmount: Self.maximumDepositUSD / 50 - 1)

            #expect(maxAmount(atCeiling) == Self.maximumDepositUSD)
            #expect(belowCeiling == nil)
        }
    }
}

// MARK: - Fixtures

private extension PolymarketDepositReceivingRestrictionsProviderTests {
    static let minCheckoutUSD: Decimal = 2
    static let maximumDepositUSD: Decimal = 50_000

    func minAmount(_ restriction: ReceivedRestriction?) -> Decimal? {
        guard case .notEnoughReceivedAmount(.fiatUSD(let minAmount), .receivingMinimum) = restriction else { return nil }
        return minAmount
    }

    func maxAmount(_ restriction: ReceivedRestriction?) -> Decimal? {
        guard case .tooMuchReceivedAmount(.fiatUSD(let maxAmount)) = restriction else { return nil }
        return maxAmount
    }

    func withProvider(
        priceUsd: Decimal?,
        backupState: UserWalletBackupState = .valid,
        operation: (PolymarketDepositReceivingRestrictionsProvider) async throws -> Void
    ) async throws {
        let tokenItem = PolymarketUtilities.usdcTokenItem

        try await InjectedDependenciesIsolation.shared.run {
            let previous = try #require(
                InjectedValues[\.quotesRepository] as? (TokenQuotesRepository & TokenQuotesRepositoryUpdater)
            )

            InjectedValues.setTokenQuotesRepository(
                MockTokenQuotesRepository(quotes: makeQuotes(tokenItem: tokenItem, priceUsd: priceUsd))
            )

            defer { InjectedValues.setTokenQuotesRepository(previous) }

            let sut = PolymarketDepositReceivingRestrictionsProvider(
                userWalletInfo: makeUserWalletInfo(backupState: backupState),
                minCheckoutUSD: Self.minCheckoutUSD,
                tokenItem: tokenItem
            )

            try await operation(sut)
        }
    }

    func makeUserWalletInfo(backupState: UserWalletBackupState) -> UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: UserWalletConfigStub(),
            backupState: backupState,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
    }

    func makeQuotes(tokenItem: TokenItem, priceUsd: Decimal?) -> Quotes {
        guard let currencyId = tokenItem.currencyId else {
            return [:]
        }

        return [
            currencyId: TokenQuote(
                currencyId: currencyId,
                price: 1,
                priceUsd: priceUsd,
                priceChange24h: nil,
                priceChange7d: nil,
                priceChange30d: nil,
                currencyCode: "USD"
            ),
        ]
    }
}
