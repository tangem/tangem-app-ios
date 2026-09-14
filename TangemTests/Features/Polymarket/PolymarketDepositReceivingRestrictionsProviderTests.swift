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

@Suite(.serialized)
struct PolymarketDepositReceivingRestrictionsProviderTests {
    @Test("A receive amount worth less than the threshold blocks the swap")
    func belowMinimumBlocks() async throws {
        let (sut, teardown) = makeSUT(priceUsd: 1)
        defer { teardown() }

        #expect(minAmount(try await sut.restriction(expectAmount: 1.5)) == Self.minimumDepositUSD)
    }

    @Test("A receive amount at the threshold or above passes")
    func aboveMinimumPasses() async throws {
        let (sut, teardown) = makeSUT(priceUsd: 1)
        defer { teardown() }

        #expect(try await sut.restriction(expectAmount: 2) == nil)
        #expect(try await sut.restriction(expectAmount: 2.5) == nil)
    }

    @Test("The threshold is converted into the deposit token, so a pricier asset needs less of it")
    func thresholdIsConvertedIntoTokenUnits() async throws {
        let (sut, teardown) = makeSUT(priceUsd: 50)
        defer { teardown() }

        #expect(try await sut.restriction(expectAmount: 0.1) == nil)
        #expect(minAmount(try await sut.restriction(expectAmount: 0.01)) == Decimal(4) / 100)
    }

    @Test("A threshold that does not divide evenly is rounded up, never below the bridge's own minimum")
    func unevenThresholdRoundsUp() async throws {
        let (sut, teardown) = makeSUT(priceUsd: 3)
        defer { teardown() }

        // $2 at $3 apiece is 0.6666…; rounded down the app would enforce less than the bridge does.
        let expected = try #require(Decimal(string: "0.666667"))

        #expect(minAmount(try await sut.restriction(expectAmount: 0.6)) == expected)
        #expect(try await sut.restriction(expectAmount: expected) == nil)
    }

    @Test("A zero price falls back to dollar parity instead of dropping the threshold")
    func zeroPriceFallsBackToDollarParity() async throws {
        let (sut, teardown) = makeSUT(priceUsd: 0)
        defer { teardown() }

        #expect(minAmount(try await sut.restriction(expectAmount: 0.0001)) == Self.minimumDepositUSD)
        #expect(try await sut.restriction(expectAmount: Self.minimumDepositUSD) == nil)
    }

    @Test("An unpriced deposit asset falls back to dollar parity, since it is a dollar stablecoin")
    func missingPriceFallsBackToDollarParity() async throws {
        let (sut, teardown) = makeSUT(priceUsd: nil)
        defer { teardown() }

        #expect(minAmount(try await sut.restriction(expectAmount: 0.0001)) == Self.minimumDepositUSD)
        #expect(try await sut.restriction(expectAmount: Self.minimumDepositUSD) == nil)
    }

    @Test("The zero-amount backup probe is answered with the backup, not with the threshold")
    func zeroAmountProbeReportsTheBackup() async throws {
        let (sut, teardown) = makeSUT(priceUsd: 1, backupState: .incompleteBackup)
        defer { teardown() }

        guard case .incompleteBackup = try await sut.restriction(expectAmount: .zero) else {
            Issue.record("The zero probe must report the incomplete backup")
            return
        }
    }

    @Test("A wallet without a backup is still blocked on an amount below the threshold")
    func belowMinimumOutranksTheBackup() async throws {
        let (sut, teardown) = makeSUT(priceUsd: 1, backupState: .incompleteBackup)
        defer { teardown() }

        #expect(minAmount(try await sut.restriction(expectAmount: 1.5)) == Self.minimumDepositUSD)
    }
}

// MARK: - Fixtures

private extension PolymarketDepositReceivingRestrictionsProviderTests {
    static let minimumDepositUSD: Decimal = 2

    func minAmount(_ restriction: ReceivedRestriction?) -> Decimal? {
        guard case .notEnoughReceivedAmount(let minAmount, .receivingMinimum) = restriction else { return nil }
        return minAmount
    }

    func makeSUT(
        priceUsd: Decimal?,
        backupState: UserWalletBackupState = .valid
    ) -> (PolymarketDepositReceivingRestrictionsProvider, () -> Void) {
        let tokenItem = PolymarketUtilities.usdcTokenItem
        let previousRepository = InjectedValues[\.quotesRepository]

        InjectedValues.setTokenQuotesRepository(
            MockTokenQuotesRepository(quotes: makeQuotes(tokenItem: tokenItem, priceUsd: priceUsd))
        )

        let sut = PolymarketDepositReceivingRestrictionsProvider(
            userWalletInfo: makeUserWalletInfo(backupState: backupState),
            minimumDepositUSD: Self.minimumDepositUSD,
            tokenItem: tokenItem
        )

        let teardown = {
            guard let previousComposite = previousRepository as? TokenQuotesRepository & TokenQuotesRepositoryUpdater else {
                Issue.record("Expected quotesRepository to conform to both TokenQuotesRepository & TokenQuotesRepositoryUpdater")
                return
            }

            InjectedValues.setTokenQuotesRepository(previousComposite)
        }

        return (sut, teardown)
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
