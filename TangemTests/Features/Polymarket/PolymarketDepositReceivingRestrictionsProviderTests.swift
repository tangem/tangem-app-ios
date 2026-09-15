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

            #expect(minAmount(belowThreshold) == Self.minimumDepositUSD)
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

    @Test("The threshold is converted into the deposit token, so a pricier asset needs less of it")
    func thresholdIsConvertedIntoTokenUnits() async throws {
        try await withProvider(priceUsd: 50) { sut in
            let aboveThreshold = try await sut.restriction(expectAmount: 0.1)
            let belowThreshold = try await sut.restriction(expectAmount: 0.01)

            #expect(aboveThreshold == nil)
            #expect(minAmount(belowThreshold) == Decimal(4) / 100)
        }
    }

    @Test("A threshold that does not divide evenly is rounded up, never below the bridge's own minimum")
    func unevenThresholdRoundsUp() async throws {
        // $2 at $3 apiece is 0.6666…; rounded down the app would enforce less than the bridge does.
        let expected = try #require(Decimal(string: "0.666667"))

        try await withProvider(priceUsd: 3) { sut in
            let belowThreshold = try await sut.restriction(expectAmount: 0.6)
            let atThreshold = try await sut.restriction(expectAmount: expected)

            #expect(minAmount(belowThreshold) == expected)
            #expect(atThreshold == nil)
        }
    }

    @Test("A zero price falls back to dollar parity instead of dropping the threshold")
    func zeroPriceFallsBackToDollarParity() async throws {
        try await withProvider(priceUsd: 0) { sut in
            let belowThreshold = try await sut.restriction(expectAmount: 0.0001)
            let atThreshold = try await sut.restriction(expectAmount: Self.minimumDepositUSD)

            #expect(minAmount(belowThreshold) == Self.minimumDepositUSD)
            #expect(atThreshold == nil)
        }
    }

    @Test("An unpriced deposit asset falls back to dollar parity, since it is a dollar stablecoin")
    func missingPriceFallsBackToDollarParity() async throws {
        try await withProvider(priceUsd: nil) { sut in
            let belowThreshold = try await sut.restriction(expectAmount: 0.0001)
            let atThreshold = try await sut.restriction(expectAmount: Self.minimumDepositUSD)

            #expect(minAmount(belowThreshold) == Self.minimumDepositUSD)
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

            #expect(minAmount(belowThreshold) == Self.minimumDepositUSD)
        }
    }
}

// MARK: - Fixtures

private extension PolymarketDepositReceivingRestrictionsProviderTests {
    static let minimumDepositUSD: Decimal = 2

    func minAmount(_ restriction: ReceivedRestriction?) -> Decimal? {
        guard case .notEnoughReceivedAmount(let minAmount, .receivingMinimum) = restriction else { return nil }
        return minAmount
    }

    /// The whole swap-restriction-restore sequence holds `InjectedDependenciesIsolation`, so parallel
    /// suites reading the quotes repository cannot observe the mock.
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
                minimumDepositUSD: Self.minimumDepositUSD,
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
