//
//  TangemPayTransactionCashbackTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPay
@testable import Tangem

@Suite("Per-transaction cashback mapped from the details response")
struct TangemPayTransactionCashbackTests {
    // MARK: - Earned

    @Test("a confirmed amount maps to earned")
    func confirmed_mapsToEarned() throws {
        let cashback = try makeCashback(cashbackJSON(status: "confirmed", amount: #""0.02""#))

        #expect(cashback == .earned(amount: decimal("0.02"), currency: "USD", capTrimmed: false))
    }

    @Test("an estimated amount maps to earned")
    func estimated_mapsToEarned() throws {
        let cashback = try makeCashback(cashbackJSON(status: "estimated", amount: #""1.50""#))

        #expect(cashback == .earned(amount: decimal("1.50"), currency: "USD", capTrimmed: false))
    }

    @Test("a negative amount is preserved for a returned purchase")
    func negativeAmount_isPreserved() throws {
        let cashback = try makeCashback(cashbackJSON(status: "confirmed", amount: #""-8.20""#))

        #expect(cashback == .earned(amount: decimal("-8.20"), currency: "USD", capTrimmed: false))
    }

    @Test("cap_trimmed is carried over", arguments: [true, false])
    func capTrimmed_isCarriedOver(capTrimmed: Bool) throws {
        let json = """
        { "cashback": { "status": "confirmed", "amount": "0.02", "currency": "USD", "cap_trimmed": \(capTrimmed) } }
        """
        let cashback = try makeCashback(json)

        #expect(cashback == .earned(amount: decimal("0.02"), currency: "USD", capTrimmed: capTrimmed))
    }

    // MARK: - Awaiting calculation

    @Test("a null amount awaiting calculation maps to its own case")
    func awaitingCalculation_mapsToOwnCase() throws {
        let json = """
        { "cashback": { "status": "awaiting_calculation", "amount": null, "currency": null } }
        """
        let cashback = try makeCashback(json)

        #expect(cashback == .awaitingCalculation)
    }

    // MARK: - Excluded

    @Test(
        "every exclusion reason maps to its own case",
        arguments: [
            ("merchant_country_excluded", TangemPayTransactionCashback.ExclusionReason.merchantCountry),
            ("mcc_excluded", .mcc),
            ("below-min", .belowMin),
            ("monthly_cap_reached", .monthlyCap),
        ]
    )
    func exclusionReason_mapsToOwnCase(
        rawValue: String,
        expected: TangemPayTransactionCashback.ExclusionReason
    ) throws {
        let cashback = try makeCashback(excludedJSON(reason: #""\#(rawValue)""#))

        #expect(cashback == .excluded(reason: expected))
    }
}

// MARK: - Helpers

private extension TangemPayTransactionCashbackTests {
    func makeCashback(_ json: String) throws -> TangemPayTransactionCashback {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let response = try decoder.decode(TangemPayCashbackTransactionDetailsResponse.self, from: Data(json.utf8))

        return try #require(TangemPayTransactionCashback(response))
    }

    func decimal(_ string: String) -> Decimal {
        guard let decimal = Decimal(string: string, locale: .posixEnUS) else {
            fatalError("Failed to parse Decimal from '\(string)'")
        }

        return decimal
    }

    func cashbackJSON(status: String, amount: String) -> String {
        """
        { "cashback": { "status": "\(status)", "amount": \(amount), "currency": "USD" } }
        """
    }

    func excludedJSON(reason: String) -> String {
        """
        { "cashback": { "status": "excluded", "amount": "0.00", "currency": "USD", "exclusion_reason": \(reason) } }
        """
    }
}
