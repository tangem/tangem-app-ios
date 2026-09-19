//
//  TangemPayTransactionRecordMapperTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPay
@testable import Tangem

@Suite("TangemPayTransactionRecordMapper: history row amounts")
struct TangemPayTransactionRecordMapperTests {
    private let formatter = TangemPayFiatAmountFormatter(locale: Locale(identifier: "en_US"))

    // MARK: - Spend

    @Test("a completed spend is shown as money leaving the card")
    func completedSpend() throws {
        let mapper = try makeMapper(spendJSON(amount: 12.5))

        #expect(mapper.amount() == "-$12.50")
        #expect(mapper.isOutgoing())
    }

    @Test("a declined spend shows the amount the merchant tried to authorize")
    func declinedSpend() throws {
        let mapper = try makeMapper(spendJSON(amount: 12.5, authorizedAmount: 50, status: "declined"))

        #expect(mapper.amount() == "-$50.00")
    }

    @Test("a zero-amount spend has no sign")
    func zeroSpend() throws {
        let mapper = try makeMapper(spendJSON(amount: 0))

        #expect(mapper.amount() == "$0.00")
    }

    @Test("a spend in a foreign currency is still shown in the card currency")
    func spendUsesCardCurrency() throws {
        let mapper = try makeMapper(spendJSON(amount: 12.5, currency: "EUR", localAmount: 22000, localCurrency: "JPY"))

        #expect(mapper.amount() == "-€12.50")
    }

    // MARK: - Refund

    @Test("a refund is shown as money coming back, with an explicit plus")
    func refund() throws {
        let mapper = try makeMapper(refundJSON(amount: -7.25))

        #expect(mapper.amount() == "+$7.25")
    }

    // MARK: - Cashback

    @Test("confirmed and estimated cashback are signed")
    func cashback() throws {
        let earned = try makeMapper(spendJSON(amount: 12.5, cashback: 0.5, cashbackStatus: "confirmed"))
        #expect(earned.cashback()?.formattedAmount == "+$0.50")
        #expect(earned.cashback()?.style == .confirmed)

        let returned = try makeMapper(refundJSON(amount: -12.5, cashback: -0.5, cashbackStatus: "estimated"))
        #expect(returned.cashback()?.formattedAmount == "-$0.50")
        #expect(returned.cashback()?.style == .estimated)
    }

    @Test("zero, excluded and pending cashback are not shown on the row")
    func hiddenCashback() throws {
        #expect(try makeMapper(spendJSON(amount: 12.5, cashback: 0, cashbackStatus: "confirmed")).cashback() == nil)
        #expect(try makeMapper(spendJSON(amount: 12.5, cashback: 0.5, cashbackStatus: "excluded")).cashback() == nil)
        #expect(try makeMapper(spendJSON(amount: 12.5, cashback: 0.5, cashbackStatus: "awaiting_calculation")).cashback() == nil)
        #expect(try makeMapper(spendJSON(amount: 12.5)).cashback() == nil)
    }

    // MARK: - Collateral, payment, fee

    @Test("collateral is shown in dollars, signed by direction")
    func collateral() throws {
        let deposit = try makeMapper(collateralJSON(amount: 100))
        #expect(deposit.amount() == "+$100.00")
        #expect(deposit.isOutgoing() == false)

        let withdrawal = try makeMapper(collateralJSON(amount: -100))
        #expect(withdrawal.amount() == "-$100.00")
        #expect(withdrawal.isOutgoing())
    }

    @Test("payments and fees are shown as money leaving the card")
    func paymentAndFee() throws {
        #expect(try makeMapper(paymentJSON(amount: 25)).amount() == "-$25.00")
        #expect(try makeMapper(feeJSON(amount: 1.5)).amount() == "-$1.50")
    }

    // MARK: - Fixtures

    private func makeMapper(_ json: String) throws -> TangemPayTransactionRecordMapper {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970

        let transaction = try decoder.decode(TangemPayTransactionRecord.self, from: Data(json.utf8))

        return TangemPayTransactionRecordMapper(transaction: transaction, amountFormatter: formatter)
    }

    private func spendJSON(
        amount: Decimal,
        authorizedAmount: Decimal? = nil,
        currency: String = "USD",
        localAmount: Decimal? = nil,
        localCurrency: String? = nil,
        status: String = "completed",
        cashback: Decimal? = nil,
        cashbackStatus: String? = nil
    ) -> String {
        """
        {
          "id": "spend-1",
          "type": "spend",
          "spend": {
            "amount": \(amount),
            "authorized_amount": \(authorizedAmount ?? amount),
            "currency": "\(currency)",
            "local_amount": \(localAmount ?? amount),
            "local_currency": "\(localCurrency ?? currency)",
            "receipt": false,
            "merchant_name": "Merchant",
            "card_id": "card-1",
            "card_type": "virtual",
            "status": "\(status)",
            "authorized_at": 1800000000,
            "cashback": \(cashback.map { "\($0)" } ?? "null"),
            "cashback_status": \(cashbackStatus.map { "\"\($0)\"" } ?? "null"),
            "cashback_currency_code": "USD"
          }
        }
        """
    }

    private func refundJSON(
        amount: Decimal,
        cashback: Decimal? = nil,
        cashbackStatus: String? = nil
    ) -> String {
        """
        {
          "id": "refund-1",
          "type": "refund",
          "refund": {
            "amount": \(amount),
            "currency": "USD",
            "merchant_name": "Merchant",
            "card_id": "card-1",
            "card_type": "virtual",
            "status": "completed",
            "authorized_at": 1800000000,
            "cashback": \(cashback.map { "\($0)" } ?? "null"),
            "cashback_status": \(cashbackStatus.map { "\"\($0)\"" } ?? "null"),
            "cashback_currency_code": "USD"
          }
        }
        """
    }

    private func collateralJSON(amount: Decimal) -> String {
        """
        {
          "id": "collateral-1",
          "type": "collateral",
          "collateral": {
            "amount": \(amount),
            "currency": "USDC",
            "posted_at": 1800000000
          }
        }
        """
    }

    private func paymentJSON(amount: Decimal) -> String {
        """
        {
          "id": "payment-1",
          "type": "payment",
          "payment": {
            "amount": \(amount),
            "currency": "USD",
            "posted_at": 1800000000
          }
        }
        """
    }

    private func feeJSON(amount: Decimal) -> String {
        """
        {
          "id": "fee-1",
          "type": "fee",
          "fee": {
            "amount": \(amount),
            "currency": "USD",
            "posted_at": 1800000000
          }
        }
        """
    }
}
