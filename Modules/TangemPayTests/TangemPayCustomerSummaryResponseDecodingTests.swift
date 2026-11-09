//
//  TangemPayCustomerSummaryResponseDecodingTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPay

@Suite("TangemPayCustomerSummaryResponse decoding")
struct TangemPayCustomerSummaryResponseDecodingTests {
    @Test("the contract example decodes field by field")
    func decodesContractExample() throws {
        let summary = try decode(
            """
            {
              "customer_id": "e363b338-6a30-4dff-95b7-ebd6188eb57b",
              "customer_status": "ACTIVE",
              "hidden": false,
              "kyc_status": "APPROVED",
              "payment_account": {
                "id": "pa-1",
                "activation": {
                  "status": "FAILED",
                  "step": "AWAITING_DEPOSIT",
                  "failure_reason": "DEPOSIT_TIMEOUT"
                },
                "cards": { "active": 1, "frozen": 2, "pending": 3 }
              },
              "banking_account": {
                "id": "ba-1",
                "activation": {
                  "status": "DEACTIVATED",
                  "step": null,
                  "failure_reason": null
                }
              }
            }
            """
        )

        #expect(summary.customerId == "e363b338-6a30-4dff-95b7-ebd6188eb57b")
        #expect(summary.customerStatus == .active)
        #expect(summary.hidden == false)
        #expect(summary.kycStatus == .approved)
        #expect(summary.paymentAccount.id == "pa-1")
        #expect(summary.paymentAccount.activation == .init(status: .failed, step: .awaitingDeposit, failureReason: .depositTimeout))
        #expect(summary.paymentAccount.cards == .init(active: 1, frozen: 2, pending: 3))
        #expect(summary.bankingAccount.id == "ba-1")
        #expect(summary.bankingAccount.activation == .init(status: .deactivated, step: nil, failureReason: nil))
    }

    @Test(
        "every activation status, step and failure reason decodes",
        arguments: [
            ("NOT_STARTED", "AWAITING_KYC", "RAIN_REJECTED"),
            ("UNAVAILABLE", "AWAITING_DEPOSIT", "DEPOSIT_TIMEOUT"),
            ("PROCESSING", "ISSUING", "TECHNICAL"),
            ("COMPLETED", "ISSUING", "TECHNICAL"),
        ]
    )
    func decodesEveryActivationValue(status: String, step: String, failureReason: String) throws {
        let summary = try decode(makeJSON(activationStatus: status, step: step, failureReason: failureReason))
        let activation = summary.paymentAccount.activation

        #expect(activation.status.rawValue == status)
        #expect(activation.step?.rawValue == step)
        #expect(activation.failureReason?.rawValue == failureReason)
    }

    @Test("values are matched regardless of letter case")
    func decodesCaseInsensitively() throws {
        let summary = try decode(
            makeJSON(
                customerStatus: "blocked",
                kycStatus: "in_progress",
                activationStatus: "processing",
                step: "awaiting_kyc",
                failureReason: "technical"
            )
        )

        #expect(summary.customerStatus == .blocked)
        #expect(summary.kycStatus == .inProgress)
        #expect(summary.paymentAccount.activation.status == .processing)
        #expect(summary.paymentAccount.activation.step == .awaitingKYC)
        #expect(summary.paymentAccount.activation.failureReason == .technical)
    }

    @Test("an unknown value falls back to undefined without failing the whole response")
    func unknownValuesFallBackToUndefined() throws {
        let summary = try decode(
            makeJSON(
                customerStatus: "RESTORED",
                kycStatus: "EXPIRED",
                activationStatus: "SUSPENDED",
                step: "AWAITING_PLAN_SELECTION",
                failureReason: "FRAUD"
            )
        )

        #expect(summary.customerStatus == .undefined)
        #expect(summary.kycStatus == .undefined)
        #expect(summary.paymentAccount.activation.status == .undefined)
        #expect(summary.paymentAccount.activation.step == .undefined)
        #expect(summary.paymentAccount.activation.failureReason == .undefined)
    }

    @Test("null id, step and failure reason decode as nil")
    func nullOptionalsDecodeAsNil() throws {
        let summary = try decode(
            """
            {
              "customer_id": "c",
              "customer_status": "NEW",
              "hidden": true,
              "kyc_status": "REQUIRED",
              "payment_account": {
                "id": null,
                "activation": { "status": "NOT_STARTED", "step": null, "failure_reason": null },
                "cards": { "active": 0, "frozen": 0, "pending": 0 }
              },
              "banking_account": {
                "id": null,
                "activation": { "status": "NOT_STARTED" }
              }
            }
            """
        )

        #expect(summary.hidden == true)
        #expect(summary.paymentAccount.id == nil)
        #expect(summary.paymentAccount.activation.step == nil)
        #expect(summary.paymentAccount.activation.failureReason == nil)
        #expect(summary.bankingAccount.id == nil)
        #expect(summary.bankingAccount.activation == .init(status: .notStarted, step: nil, failureReason: nil))
    }

    @Test("a response without a product object fails to decode")
    func missingProductObjectFailsDecoding() {
        #expect(throws: DecodingError.self) {
            try decode(
                """
                {
                  "customer_id": "c",
                  "customer_status": "NEW",
                  "hidden": false,
                  "kyc_status": "APPROVED"
                }
                """
            )
        }
    }

    @Test("the response survives an encode/decode round trip for the disk cache")
    func roundTripsThroughCodable() throws {
        let original = try decode(makeJSON(activationStatus: "COMPLETED", step: nil, failureReason: nil))

        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(TangemPayCustomerSummaryResponse.self, from: data)

        #expect(restored == original)
    }

    // MARK: - Helpers

    private func decode(_ json: String) throws -> TangemPayCustomerSummaryResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(TangemPayCustomerSummaryResponse.self, from: Data(json.utf8))
    }

    private func makeJSON(
        customerStatus: String = "ACTIVE",
        kycStatus: String = "APPROVED",
        activationStatus: String,
        step: String?,
        failureReason: String?
    ) -> String {
        let quoted: (String?) -> String = { $0.map { "\"\($0)\"" } ?? "null" }

        return """
        {
          "customer_id": "c",
          "customer_status": "\(customerStatus)",
          "hidden": false,
          "kyc_status": "\(kycStatus)",
          "payment_account": {
            "id": "pa",
            "activation": {
              "status": "\(activationStatus)",
              "step": \(quoted(step)),
              "failure_reason": \(quoted(failureReason))
            },
            "cards": { "active": 0, "frozen": 0, "pending": 0 }
          },
          "banking_account": {
            "id": null,
            "activation": { "status": "NOT_STARTED", "step": null, "failure_reason": null }
          }
        }
        """
    }
}
