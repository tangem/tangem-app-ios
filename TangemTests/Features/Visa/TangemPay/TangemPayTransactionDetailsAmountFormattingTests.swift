//
//  TangemPayTransactionDetailsAmountFormattingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
@testable import Tangem

@Suite("Tangem Pay transaction details: amounts")
struct TangemPayTransactionDetailsAmountFormattingTests {
    private let formatter = TangemPayFiatAmountFormatter(locale: Locale(identifier: "en_US"))

    // MARK: - Spend input

    @Test("a completed charge is shown as money leaving the card")
    func completedChargeIsNegative() {
        let input = makeSpend(amount: "12.3")

        #expect(input.formattedAmount(using: formatter) == "-$12.30")
    }

    @Test("a refund is shown as money coming back, with an explicit plus")
    func refundIsPositive() {
        let input = makeSpend(amount: "-12.3")

        #expect(input.formattedAmount(using: formatter) == "+$12.30")
    }

    @Test("a declined charge shows the amount the merchant tried to authorize")
    func declinedChargeShowsAuthorizedAmount() {
        let input = makeSpend(amount: "12.3", authorizedAmount: "50", status: .declined)

        #expect(input.formattedAmount(using: formatter) == "-$50.00")
    }

    @Test("a zero amount stays a plain zero, even when declined")
    func zeroAmountIsUnsigned() {
        #expect(makeSpend(amount: "0").formattedAmount(using: formatter) == "$0.00")
        #expect(makeSpend(amount: "0", authorizedAmount: "50", status: .declined).formattedAmount(using: formatter) == "$0.00")
    }

    @Test("the local amount is signed like the card amount and uses the merchant's currency")
    func localAmountFollowsCardAmountSign() {
        let charge = makeSpend(amount: "12.3", localAmount: "10.5", localCurrency: "EUR")
        let refund = makeSpend(amount: "-12.3", localAmount: "-10.5", localCurrency: "EUR")

        #expect(charge.formattedLocalAmount(using: formatter) == "-€10.50")
        #expect(refund.formattedLocalAmount(using: formatter) == "+€10.50")
    }

    @Test("no local amount when the merchant charged in the card currency or the local amount is unknown")
    func localAmountIsHiddenWhenRedundant() {
        #expect(makeSpend(amount: "12.3", localAmount: "12.3", localCurrency: "USD").formattedLocalAmount(using: formatter) == nil)
        #expect(makeSpend(amount: "12.3", localAmount: nil, localCurrency: "EUR").formattedLocalAmount(using: formatter) == nil)
        #expect(makeSpend(amount: "12.3", localAmount: "10.5", localCurrency: nil).formattedLocalAmount(using: formatter) == nil)
    }

    // MARK: - Legacy mapper

    @Test("legacy details use the same amount shape as the history row")
    func legacyMapperSpendAmounts() {
        let mapper = TangemPayDisplayDataMapper(amountFormatter: formatter)
        let data = mapper.map(spend: makeSpend(amount: "12345.675", localAmount: "11000.5", localCurrency: "EUR"))

        #expect(data.amount == "-$12,345.68")
        #expect(data.localAmount == "-€11,000.50")
    }

    @Test("legacy details: deposits, withdrawals, payments and fees")
    func legacyMapperTransferAmounts() {
        let mapper = TangemPayDisplayDataMapper(amountFormatter: formatter)

        #expect(mapper.map(collateral: .init(postedAt: date, amount: decimal("100"), isOutgoing: false)).amount == "+$100.00")
        #expect(mapper.map(collateral: .init(postedAt: date, amount: decimal("-100"), isOutgoing: true)).amount == "-$100.00")
        #expect(mapper.map(payment: .init(postedAt: date, amount: decimal("25"), currency: "USD")).amount == "-$25.00")
        #expect(mapper.map(fee: .init(postedAt: date, amount: decimal("1.5"), currency: "USD", description: nil)).amount == "-$1.50")
    }

    // MARK: - Redesigned mapper

    @Test("redesigned details: the foreign amount is part of the subtitle")
    func redesignedMapperSpendAmounts() {
        let mapper = TangemPayTransactionDetailsRedesignedMapper(amountFormatter: formatter)
        let model = mapper.map(spend: makeSpend(amount: "12.3", localAmount: "10.5", localCurrency: "EUR", merchantName: "Coffee"))

        #expect(model.amount == "-$12.30")
        #expect(model.amountSubtitle == "-€10.50 \(AppConstants.dotSign) Coffee")
    }

    @Test("redesigned details: a charge in the card currency shows just the merchant")
    func redesignedMapperSameCurrencySubtitle() {
        let mapper = TangemPayTransactionDetailsRedesignedMapper(amountFormatter: formatter)
        let model = mapper.map(spend: makeSpend(amount: "12.3", localAmount: "12.3", localCurrency: "USD", merchantName: "Coffee"))

        #expect(model.amountSubtitle == "Coffee")
    }

    @Test("redesigned details: deposits, withdrawals, payments and fees")
    func redesignedMapperTransferAmounts() {
        let mapper = TangemPayTransactionDetailsRedesignedMapper(amountFormatter: formatter)

        #expect(mapper.map(collateral: .init(postedAt: date, amount: decimal("100"), isOutgoing: false)).amount == "+$100.00")
        #expect(mapper.map(collateral: .init(postedAt: date, amount: decimal("-100"), isOutgoing: true)).amount == "-$100.00")
        #expect(mapper.map(payment: .init(postedAt: date, amount: decimal("25"), currency: "USD")).amount == "-$25.00")
        #expect(mapper.map(fee: .init(postedAt: date, amount: decimal("1.5"), currency: "USD", description: nil)).amount == "-$1.50")
    }

    @Test("redesigned details: earned cashback is signed")
    func redesignedMapperCashback() {
        let mapper = TangemPayTransactionDetailsRedesignedMapper(amountFormatter: formatter)

        let earned = mapper.map(cashback: .earned(amount: decimal("0.5"), currency: "USD", capTrimmed: false))
        #expect(earned == .loaded(.init(value: .amount("+$0.50"), subvalue: nil)))

        let returned = mapper.map(cashback: .earned(amount: decimal("-8.2"), currency: "USD", capTrimmed: false))
        #expect(returned == .loaded(.init(value: .amount("-$8.20"), subvalue: Localization.tangemPayTransactionDetailsCashbackRefund)))
    }

    // MARK: - Helpers

    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeSpend(
        amount: String,
        authorizedAmount: String? = nil,
        currency: String = "USD",
        localAmount: String? = nil,
        localCurrency: String? = nil,
        status: TangemPaySpendDisplayInput.Status = .completed,
        merchantName: String? = "Merchant"
    ) -> TangemPaySpendDisplayInput {
        TangemPaySpendDisplayInput(
            transactionDate: date,
            merchantName: merchantName,
            enrichedMerchantName: nil,
            enrichedMerchantIcon: nil,
            amount: decimal(amount),
            authorizedAmount: decimal(authorizedAmount ?? amount),
            currency: currency,
            localAmount: localAmount.map(decimal),
            localCurrency: localCurrency,
            merchantCategory: nil,
            enrichedMerchantCategory: nil,
            merchantCategoryCode: nil,
            status: status,
            declinedReason: nil
        )
    }

    private func decimal(_ string: String) -> Decimal {
        Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")) ?? .zero
    }
}
