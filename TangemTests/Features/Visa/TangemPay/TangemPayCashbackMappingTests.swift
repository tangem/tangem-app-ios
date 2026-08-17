//
//  TangemPayCashbackMappingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPay
@testable import Tangem

@Suite("TangemPayCashback mapped from the summary response")
struct TangemPayCashbackMappingTests {
    // MARK: - Happy path

    @Test("full display mode maps to available")
    func fullMode_mapsToAvailable() throws {
        let cashback = try makeCashback(enabledJSON())

        #expect(
            cashback == .available(
                TangemPayCashback.Summary(
                    displayMode: .full,
                    confirmedAmount: decimal("22.54"),
                    totalEarnedAmount: decimal("153.01"),
                    currency: "USD",
                    period: TangemPayCashback.Period(
                        year: 2026,
                        month: 8,
                        payoutStartDate: utcDate(year: 2026, month: 9, day: 2),
                        payoutEndDate: utcDate(year: 2026, month: 9, day: 5)
                    ),
                    previousPayout: TangemPayCashback.PreviousPayout(
                        amount: decimal("18.30"),
                        endDate: utcDate(year: 2026, month: 8, day: 5)
                    )
                )
            )
        )
    }

    @Test("alt_block maps to the alternative display mode")
    func altBlock_mapsToAlternative() throws {
        let cashback = try makeCashback(enabledJSON(displayMode: #""alt_block""#))

        #expect(cashback.summary?.displayMode == .alternative)
    }

    @Test("an absent display mode falls back to full")
    func absentDisplayMode_fallsBackToFull() throws {
        let cashback = try makeCashback(enabledJSON(displayMode: nil))

        #expect(cashback.summary?.displayMode == .full)
    }

    @Test("a zero amount stays available")
    func zeroAmount_staysAvailable() throws {
        let cashback = try makeCashback(enabledJSON(confirmedAmount: #""0.00""#))

        #expect(cashback.summary?.confirmedAmount == .zero)
    }

    @Test("a negative amount is preserved for the refund period")
    func negativeAmount_isPreserved() throws {
        let cashback = try makeCashback(enabledJSON(confirmedAmount: #""-3.20""#))

        #expect(cashback.summary?.confirmedAmount == decimal("-3.20"))
    }

    // MARK: - Other program statuses

    @Test("disabled maps to unavailable")
    func disabled_mapsToUnavailable() throws {
        let cashback = try makeCashback(#"{ "cashback_program_status": "disabled" }"#)

        #expect(cashback == .unavailable)
    }

    @Test("fraud maps to blocked")
    func fraud_mapsToBlocked() throws {
        let cashback = try makeCashback(#"{ "cashback_program_status": "fraud" }"#)

        #expect(cashback == .blocked)
    }

    // MARK: - Failures

    @Test("an unparseable amount degrades to unavailable")
    func unparseableAmount_degradesToUnavailable() throws {
        let cashback = try makeCashback(enabledJSON(confirmedAmount: #""not-a-number""#))

        #expect(cashback == .unavailable)
    }

    @Test("a missing amount degrades to unavailable")
    func missingAmount_degradesToUnavailable() throws {
        let cashback = try makeCashback(enabledJSON(confirmedAmount: nil))

        #expect(cashback == .unavailable)
    }

    @Test("a missing period degrades to unavailable")
    func missingPeriod_degradesToUnavailable() throws {
        let cashback = try makeCashback(enabledJSON(period: nil))

        #expect(cashback == .unavailable)
    }

    @Test("a response without a program status fails to decode")
    func missingStatus_failsToDecode() {
        #expect(throws: DecodingError.self) {
            try makeCashback("{}")
        }
    }
}

// MARK: - Helpers

private extension TangemPayCashbackMappingTests {
    func makeCashback(_ json: String) throws -> TangemPayCashback {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let response = try decoder.decode(TangemPayCashbackSummaryResponse.self, from: Data(json.utf8))

        return TangemPayCashback(response)
    }

    func decimal(_ string: String) -> Decimal {
        Decimal(string: string, locale: .posixEnUS) ?? .zero
    }

    func utcDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.timeZone = TimeZone(secondsFromGMT: 0)

        guard let date = Calendar(identifier: .gregorian).date(from: components) else {
            preconditionFailure("Failed to build UTC date from components: \(components)")
        }

        return date
    }

    func enabledJSON(
        displayMode: String? = #""full""#,
        confirmedAmount: String? = #""22.54""#,
        totalEarnedAmount: String? = #""153.01""#,
        previousPayoutAmount: String? = #""18.30""#,
        previousPayoutEndDate: String? = #""2026-08-05""#,
        period: String? = Self.periodJSON
    ) -> String {
        var members = [#""cashback_program_status": "enabled""#]

        if let displayMode {
            members.append(#""cashback_display_mode": \#(displayMode)"#)
        }

        if let period {
            members.append(#""period": \#(period)"#)
        }

        if let confirmedAmount {
            members.append(#""confirmed_amount": \#(confirmedAmount)"#)
        }

        if let totalEarnedAmount {
            members.append(#""total_earned_amount": \#(totalEarnedAmount)"#)
        }

        if let previousPayoutEndDate {
            members.append(#""previous_payout_end_date": \#(previousPayoutEndDate)"#)
        }

        if let previousPayoutAmount {
            members.append(#""previous_payout_amount": \#(previousPayoutAmount)"#)
        }

        members.append(#""currency": "USD""#)

        return "{ \(members.joined(separator: ", ")) }"
    }

    static let periodJSON = """
    { "year": 2026, "month": 8, "payout_start_date": "2026-09-02", "payout_end_date": "2026-09-05" }
    """
}

private extension TangemPayCashback {
    var summary: Summary? {
        switch self {
        case .available(let summary): summary
        case .unavailable, .blocked: nil
        }
    }
}
