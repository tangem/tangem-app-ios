//
//  TransactionDetailsSwapLegsTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
@testable import Tangem

@Suite("TransactionDetailsSwapViewData legs")
struct TransactionDetailsSwapLegsTests {
    @Test("A leg that knows where it leaves from or lands names it as From / To")
    func legsWithActorsNameBothSides() {
        let holder = TransactionDetailsActor.wallet(name: "Main wallet")
        let recipient = TransactionDetailsActor.address(short: "33Bd3...a21412B", blockiesImage: .init(image: nil))

        let data = makeSwapViewData(sourceActor: holder, destinationActor: recipient)

        guard case .pair(let from, let to) = data.tokensData.content else {
            Issue.record("expected a pair of legs for a swap")
            return
        }

        #expect(from.direction == .init(label: Localization.commonFrom, actor: holder))
        #expect(to.direction == .init(label: Localization.commonTo, actor: recipient))
    }

    @Test("A leg that doesn't know it keeps the plain You send / You receive caption")
    func legsWithoutActorsKeepThePlainCaption() {
        let data = makeSwapViewData(sourceActor: nil, destinationActor: nil)

        guard case .pair(let from, let to) = data.tokensData.content else {
            Issue.record("expected a pair of legs for a swap")
            return
        }

        #expect(from.direction == .init(label: Localization.swappingFromTitleV2, actor: nil))
        #expect(to.direction == .init(label: Localization.swappingToTitle, actor: nil))
    }
}

// MARK: - Helpers

private extension TransactionDetailsSwapLegsTests {
    func makeSwapViewData(
        sourceActor: TransactionDetailsActor?,
        destinationActor: TransactionDetailsActor?
    ) -> TransactionDetailsSwapViewData {
        TransactionDetailsSwapViewData(
            stage: .finished,
            source: .init(amount: "390", symbol: "USDT", tokenIconInfo: nil, actor: sourceActor),
            destination: .init(amount: "1800", symbol: "POL", tokenIconInfo: nil, actor: destinationActor),
            isDestinationEstimated: false,
            statusBanner: nil,
            provider: nil,
            rate: nil,
            networkFee: nil,
            action: nil,
            ratingTransaction: nil
        )
    }
}
