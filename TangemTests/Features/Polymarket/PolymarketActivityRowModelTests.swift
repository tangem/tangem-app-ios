//
//  PolymarketActivityRowModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

@Suite("Polymarket history row")
struct PolymarketActivityRowModelTests {
    @Test("A withdrawal shows its transaction hash, shortened in the middle", arguments: [PolymarketActivityType.withdraw, .deposit])
    func fundingShowsHash(type: PolymarketActivityType) {
        let model = PolymarketActivityRow.Model.make(record: .funding(type: type, hash: Self.hash))

        #expect(model.subtitle == Self.hash)
        #expect(model.truncatesSubtitleInMiddle)
    }

    @Test("A funding row without a hash has no subtitle")
    func fundingWithoutHash() {
        let model = PolymarketActivityRow.Model.make(record: .funding(type: .withdraw, hash: nil))

        #expect(model.subtitle == nil)
    }

    @Test("A claim is titled and toned by its result", arguments: [
        ClaimCase(result: .won, title: Localization.predictionHistoryRedeemed, tone: .positive),
        ClaimCase(result: .split, title: Localization.predictionPositionsSplit, tone: .neutral),
        ClaimCase(result: .lost, title: Localization.predictionPositionsLost, tone: .neutral),
        ClaimCase(result: nil, title: Localization.predictionHistoryRedeemed, tone: .positive),
    ])
    func claimIsTitledByItsResult(claimCase: ClaimCase) {
        let model = PolymarketActivityRow.Model.make(record: .claim(result: claimCase.result))

        #expect(model.title == claimCase.title)
        #expect(model.tone == claimCase.tone)
    }
}

extension PolymarketActivityRowModelTests {
    struct ClaimCase: Sendable, CustomTestStringConvertible {
        let result: PolymarketRedeemResult?
        let title: String
        let tone: PolymarketValueTone

        var testDescription: String { result?.rawValue ?? "no result" }
    }
}

// MARK: - Helpers

private extension PolymarketActivityRowModelTests {
    static let hash = "0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
}

private extension PolymarketActivityRecord {
    static func funding(type: PolymarketActivityType, hash: String?) -> PolymarketActivityRecord {
        PolymarketActivityRecord(
            id: "1",
            type: type,
            occurredAt: Date(timeIntervalSince1970: 0),
            amount: 5,
            transactionHash: hash,
            market: nil,
            order: nil,
            redeemResult: nil
        )
    }

    static func claim(result: PolymarketRedeemResult?) -> PolymarketActivityRecord {
        PolymarketActivityRecord(
            id: "claim",
            type: .redeem,
            occurredAt: Date(timeIntervalSince1970: 0),
            amount: 5,
            transactionHash: nil,
            market: nil,
            order: nil,
            redeemResult: result
        )
    }
}
