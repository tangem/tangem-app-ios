//
//  TangemPayPushPayloadTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

struct TangemPayPushPayloadTests {
    // MARK: - Fixtures

    private static let spendFields: [String: String] = [
        "transaction_id": "43215123",
        "amount": "249.99",
        "currency": "EUR",
        "authorized_at": "2026-04-07T10:30:00.000",
        "status": "approved",
        "merchant_name": "Amazon",
        "enriched_merchant_name": "Amazon.com",
        "merchant_category": "Online Shopping",
        "merchant_category_code": "5411",
        "enriched_merchant_category": "E-Commerce",
        "enriched_merchant_icon": "https://icon.example.com/amazon.png",
        "balance": "750.01",
        "local_amount": "22000",
        "local_currency": "JPY",
        "last4": "5461",
    ]

    private static let collateralFields: [String: String] = [
        "transaction_id": "43215123",
        "amount": "500.00",
        "currency": "EUR",
        "posted_at": "2026-04-07T10:00:00.000",
        "balance": "10000.00",
        "transaction_hash": "0xabc123def456",
    ]

    private static func makeUserInfo(
        type: String,
        bodyFields: [String: String] = [:]
    ) -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [
            "type": type,
            "customer_wallet_id": "8CD315E42BA5BD6AB6045C254A5F41BA9969E17F882A2CF7602544B870DF7D7B",
            "customer_id": "32080398-6b36-4cd5-af29-bfe18cfa30d5",
        ]
        for (key, value) in bodyFields {
            dict[key] = value
        }
        return dict
    }

    // MARK: - Body dispatch

    private static let dispatchArguments: [(type: String, bodyFields: [String: String])] = [
        (type: "card_ready", bodyFields: [:]),
        (type: "transaction_spend", bodyFields: spendFields),
        (type: "transaction_spend_refund", bodyFields: spendFields),
        (type: "declined_top_up", bodyFields: spendFields),
        (type: "declined_reason1", bodyFields: spendFields),
        (type: "declined_reason9", bodyFields: spendFields),
        (type: "declined_reason17", bodyFields: spendFields),
        (type: "collateral_withdraw", bodyFields: collateralFields),
        (type: "collateral_deposit", bodyFields: collateralFields),
        (type: "threshold1_top_up", bodyFields: [:]),
    ]

    @Test("Parses each push type into the matching body case", arguments: dispatchArguments)
    func bodyDispatch(type: String, bodyFields: [String: String]) {
        let payload = TangemPayPushPayload.parse(from: Self.makeUserInfo(type: type, bodyFields: bodyFields))

        guard let payload else {
            #expect(Bool(false), "Expected parse to succeed for type '\(type)'")
            return
        }

        // `rawType` derives from `body` case by case, so the round-trip checks the dispatch and
        // guarantees the support-request JSON carries exactly the type that arrived.
        #expect(payload.rawType.rawValue == type)
    }

    @Test(
        "Rejects an unsupported declined reason type",
        arguments: [
            "declined_reason",
            "declined_reason0",
            "declined_reason07",
            "declined_reason18",
        ]
    )
    func rejectsUnsupportedDeclinedReasonType(type: String) {
        #expect(TangemPayPushPayload.parse(from: Self.makeUserInfo(type: type, bodyFields: Self.spendFields)) == nil)
    }

    // MARK: - Value coercion

    @Test("Coerces string decimals, ISO8601 dates, and URLs")
    func valueCoercion() {
        let payload = TangemPayPushPayload.parse(from: Self.makeUserInfo(type: "transaction_spend", bodyFields: Self.spendFields))

        guard case .transactionSpend(let spend) = payload?.body else {
            #expect(Bool(false), "Expected .transactionSpend body")
            return
        }

        #expect(spend.amount == Decimal(string: "249.99"))
        #expect(spend.balance == Decimal(string: "750.01"))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        #expect(spend.authorizedAt == dateFormatter.date(from: "2026-04-07T10:30:00.000"))
        #expect(spend.enrichedMerchantIcon == URL(string: "https://icon.example.com/amazon.png"))
    }

    // MARK: - Envelope rejection

    @Test(
        "Rejects invalid envelope",
        arguments: [
            ["type": "transaction_spend", "customer_id": "y"], // missing customer_wallet_id
            ["type": "transaction_spend", "customer_wallet_id": "x"], // missing customer_id
            ["customer_wallet_id": "x", "customer_id": "y"], // missing type
            ["type": "refund_requested", "customer_wallet_id": "x", "customer_id": "y"], // unknown type
            ["type": "transaction_spend", "customer_wallet_id": "", "customer_id": "y"], // empty-string required field
        ]
    )
    func rejectsInvalidEnvelope(userInfo: [String: String]) {
        let dict: [AnyHashable: Any] = userInfo.reduce(into: [:]) { $0[$1.key] = $1.value }
        #expect(TangemPayPushPayload.parse(from: dict) == nil)
    }

    // MARK: - Body field rejection

    @Test(
        "Rejects spend with missing required field",
        arguments: ["transaction_id", "amount", "currency", "authorized_at", "status"]
    )
    func rejectsIncompleteSpend(missingKey: String) {
        var fields = Self.spendFields
        fields.removeValue(forKey: missingKey)
        let userInfo = Self.makeUserInfo(type: "transaction_spend", bodyFields: fields)
        #expect(TangemPayPushPayload.parse(from: userInfo) == nil)
    }

    @Test(
        "Rejects collateral with missing required field",
        arguments: ["transaction_id", "amount", "currency", "posted_at"]
    )
    func rejectsIncompleteCollateral(missingKey: String) {
        var fields = Self.collateralFields
        fields.removeValue(forKey: missingKey)
        let userInfo = Self.makeUserInfo(type: "collateral_withdraw", bodyFields: fields)
        #expect(TangemPayPushPayload.parse(from: userInfo) == nil)
    }

    @Test("Rejects unknown spend status")
    func rejectsUnknownStatus() {
        var fields = Self.spendFields
        fields["status"] = "chargeback"
        let userInfo = Self.makeUserInfo(type: "transaction_spend", bodyFields: fields)
        #expect(TangemPayPushPayload.parse(from: userInfo) == nil)
    }
}
