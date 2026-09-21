//
//  OnrampHistoryMatcherTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("OnrampHistoryMatcher")
struct OnrampHistoryMatcherTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("Picks the history item created closest to `since`, not the newest one in the window")
    func picksClosestToSince() {
        let first = makeTransaction(txId: "first", createdAt: t0.addingTimeInterval(20))
        let second = makeTransaction(txId: "second", createdAt: t0.addingTimeInterval(5 * 60))

        let match = findMatch(in: [second, first], since: t0)

        #expect(match?.txId == "first")
    }

    @Test("Two purchases within the window resolve one-to-one when matched items are excluded")
    func twoPurchasesResolveOneToOne() {
        let first = makeTransaction(txId: "first", createdAt: t0.addingTimeInterval(20))
        let second = makeTransaction(txId: "second", createdAt: t0.addingTimeInterval(5 * 60 + 20))
        let history = [second, first]

        let firstMatch = findMatch(in: history, since: t0)
        let secondMatch = findMatch(in: history, since: t0.addingTimeInterval(5 * 60), excluding: [firstMatch?.txId].compactMap { $0 })

        #expect(firstMatch?.txId == "first")
        #expect(secondMatch?.txId == "second")
    }

    @Test("Excluded, out-of-window and terminal-failure items are not candidates")
    func filtersCandidates() {
        let excluded = makeTransaction(txId: "excluded", createdAt: t0.addingTimeInterval(10))
        let tooOld = makeTransaction(txId: "old", createdAt: t0.addingTimeInterval(-60))
        let failed = makeTransaction(txId: "failed", createdAt: t0.addingTimeInterval(30), status: .failed)

        #expect(findMatch(in: [excluded, tooOld, failed], since: t0, excluding: ["excluded"]) == nil)
    }

    // MARK: - Helpers

    private func findMatch(in records: [OnrampTransaction], since: Date, excluding: [String] = []) -> OnrampTransaction? {
        OnrampHistoryMatcher.findMatch(
            in: records,
            since: since,
            toContractAddress: "0x0",
            toNetwork: "ethereum",
            providerId: "mercuryo",
            excludingTxIds: Set(excluding)
        )
    }

    private func makeTransaction(txId: String, createdAt: Date, status: OnrampTransactionStatus = .paid) -> OnrampTransaction {
        OnrampTransaction(
            txId: txId,
            providerId: "mercuryo",
            status: status,
            failReason: nil,
            externalTx: nil,
            payOut: PayOutInfo(address: "0xpayout", hash: nil),
            from: OnrampHistoryFiatAsset(currencyCode: "EUR", amount: 100),
            to: OnrampHistoryCryptoAsset(currency: ExpressCurrency(contractAddress: "0x0", network: "ethereum"), amount: nil, actualAmount: nil, decimals: 18),
            paymentMethod: "card",
            countryCode: "DE",
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}
