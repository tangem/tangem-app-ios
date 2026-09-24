//
//  TransactionDetailsInfoRowSensitivityTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemUI
@testable import Tangem

/// Masking itself belongs to `SensitiveText` and isn't tested here. What is pinned is the decision these view
/// data builders make: which info rows are handed over as maskable at all. Getting that wrong either leaks a
/// balance-derived value while balances are hidden, or hides a market rate that should stay readable — and
/// neither is visible in the row's title or value.
@Suite("Transaction details info rows sensitivity")
struct TransactionDetailsInfoRowSensitivityTests {
    @Test("Swap marks the network fee as maskable and keeps the rate readable")
    func swapRowsSensitivity() throws {
        let rows = try #require(makeSwapViewData(rate: "1 POL ≈ 0,077 USDT", networkFee: "0.00056 ETH").infoData?.rows)

        #expect(rows.map(\.id) == ["rate", "networkFee"])
        #expect(rows.first?.content == .text("1 POL ≈ 0,077 USDT"))
        #expect(rows.last?.content == .sensitiveText("0.00056 ETH"))
    }

    @Test("Onramp surfaces the rate only, and never as a maskable value")
    func onrampRowsSensitivity() throws {
        let rows = try #require(makeOnrampViewData(rate: "1 POL ≈ 0,077 USDT").infoData?.rows)

        #expect(rows.map(\.content) == [.text("1 POL ≈ 0,077 USDT")])
    }
}

// MARK: - Fixtures

private extension TransactionDetailsInfoRowSensitivityTests {
    func makeSwapViewData(rate: String?, networkFee: String?) -> TransactionDetailsSwapViewData {
        TransactionDetailsSwapViewData(
            stage: .finished,
            source: .init(amount: "390", symbol: "USDT", tokenIconInfo: nil),
            destination: .init(amount: "1800", symbol: "POL", tokenIconInfo: nil),
            isDestinationEstimated: false,
            statusBanner: nil,
            provider: nil,
            rate: rate,
            networkFee: networkFee,
            action: nil,
            ratingTransaction: nil
        )
    }

    func makeOnrampViewData(rate: String?) -> TransactionDetailsOnrampViewData {
        TransactionDetailsOnrampViewData(
            stage: .finished,
            paid: .init(amount: "100", symbol: "EUR", flagIconURL: nil, isFlagLoading: false),
            received: .init(
                destination: .wallet(name: "Wallet"),
                amount: "1800",
                symbol: "POL",
                tokenIconInfo: .remote(name: "Polygon", imageURL: nil)
            ),
            statusBanner: nil,
            provider: nil,
            rate: rate,
            action: nil
        )
    }
}
