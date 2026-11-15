//
//  JointAccountErrorAnalyticsParametersTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("Tests for what a joint account error is reported with")
struct JointAccountErrorAnalyticsParametersTests {
    @Test("A refusal carrying the backend's own reason is reported by that reason")
    func backendReasonIsTheCode() {
        let error = TangemAPIError(code: .badRequest, message: "Nonce mismatch", reasonCode: "NONCE_MISMATCH")

        let params = JointAccountErrorAnalyticsParameters(source: .sign, error: error).build()

        #expect(params == [.source: "Sign", .errorCode: "NONCE_MISMATCH", .errorMessage: "Nonce mismatch"])
    }

    @Test("A refusal without a reason is reported by its HTTP status")
    func statusIsTheCodeWithoutAReason() {
        let error = TangemAPIError(code: .conflict, message: "Conflict")

        let params = JointAccountErrorAnalyticsParameters(source: .decline, error: error).build()

        #expect(params == [.source: "Decline", .errorCode: "409", .errorMessage: "Conflict"])
    }

    @Test("A refusal is read through what the flow wrapped it in")
    func wrappedRefusalIsUnwrapped() {
        let apiError = TangemAPIError(code: .forbidden, message: "Forbidden", reasonCode: "NOT_A_MEMBER")
        let creationError = AccountEditError.unknownError(apiError)
        let sendError = SendTxError(error: apiError.toUniversalError())

        let creationParams = JointAccountErrorAnalyticsParameters(source: .create, error: creationError).build()
        let sendParams = JointAccountErrorAnalyticsParameters(source: .createOperation, error: sendError).build()

        #expect(creationParams == [.source: "Create", .errorCode: "NOT_A_MEMBER", .errorMessage: "Forbidden"])
        #expect(sendParams == [.source: "Create Operation", .errorCode: "NOT_A_MEMBER", .errorMessage: "Forbidden"])
    }

    @Test(
        "A new operation the backend refused is reported by the reason it gave, one this version has never heard of included",
        arguments: [
            "UNSUPPORTED_CHAIN",
            "NONCE_MISMATCH",
            "INVALID_BASE_GAS",
            "GAS_PRICE_TOO_LOW",
            "GAS_PRICE_TOO_HIGH",
            "GAS_TOKEN_NOT_ALLOWED",
            "INVALID_REFUND_RECEIVER",
            "INVALID_SAFE_OPERATION",
            "INVALID_SAFE_ADDRESS",
            "STALE_NONCE",
        ]
    )
    func refusedOperationIsReportedByItsReason(reasonCode: String) {
        let error = SendTxError(error: JointOperationError.refused(JointOperationRefusal(reasonCode: reasonCode)))

        let params = JointAccountErrorAnalyticsParameters(source: .createOperation, error: error).build()

        #expect(params[.source] == "Create Operation")
        #expect(params[.errorCode] == reasonCode)
    }

    @Test("A failure is described without the request it failed on or the values it carries")
    func failureIsDescribedWithoutItsPayload() {
        let walletId = "0a0b0c0d"
        let systemError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [
            NSLocalizedDescriptionKey: "The Internet connection appears to be offline.",
            NSURLErrorFailingURLStringErrorKey: "https://api.tangem.org/v1/wallets/\(walletId)/joint-accounts",
        ])
        let payloadError = PayloadError.walletMissing(id: walletId)

        let systemParams = JointAccountErrorAnalyticsParameters(source: .join, error: systemError).build()
        let payloadParams = JointAccountErrorAnalyticsParameters(source: .create, error: payloadError).build()

        #expect(systemParams[.errorMessage] == "The Internet connection appears to be offline.")
        #expect(payloadParams[.errorMessage]?.contains(walletId) == false)
    }

    @Test("A failure that never reached the backend has no code")
    func localFailureHasNoCode() {
        let error = JointOperationError.maliciousOperation

        let params = JointAccountErrorAnalyticsParameters(source: .sign, error: error).build()

        #expect(params == [.source: "Sign", .errorMessage: "JointOperationError.maliciousOperation"])
    }

    @Test("An app's own failure is reported by its case, whatever language the app speaks")
    func ownFailureIsReportedByItsCase() {
        let operationError = SendTxError(error: JointOperationError.refused(JointOperationRefusal(reasonCode: "NONCE_MISMATCH")))
        let creationError = AccountEditError.duplicateAccountName

        let operationParams = JointAccountErrorAnalyticsParameters(source: .createOperation, error: operationError).build()
        let creationParams = JointAccountErrorAnalyticsParameters(source: .create, error: creationError).build()

        #expect(operationParams[.errorMessage] == "JointOperationError.refused")
        #expect(creationParams[.errorMessage] == "AccountEditError.duplicateAccountName")
    }
}

// MARK: - Stubs

private enum PayloadError: Error {
    case walletMissing(id: String)
}
