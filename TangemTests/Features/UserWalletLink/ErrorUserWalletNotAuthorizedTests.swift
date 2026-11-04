//
//  ErrorUserWalletNotAuthorizedTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
import TangemNetworkUtils
@testable import Tangem

@Suite("User wallet not authorized error")
struct ErrorUserWalletNotAuthorizedTests {
    @Test(
        "A 403 response with the wallet-not-authorized code is recognized whichever field carries the code",
        arguments: [
            #"{"statusCode":403,"errorCode":"WALLET_NOT_AUTHORIZED"}"#,
            #"{"statusCode":403,"code":"WALLET_NOT_AUTHORIZED","message":"Wallet is not authorized"}"#,
            #"{"status":403,"detail":"Wallet is not authorized","code":"WALLET_NOT_AUTHORIZED"}"#,
        ]
    )
    func walletNotAuthorizedResponseIsRecognized(body: String) {
        let error = makeMoyaError(statusCode: 403, body: body)

        #expect(error.isUserWalletNotAuthorized)
    }

    @Test(
        "Other responses are not recognized",
        arguments: [
            (statusCode: 401, body: #"{"statusCode":401,"errorCode":"WALLET_NOT_AUTHORIZED"}"#),
            (statusCode: 403, body: #"{"statusCode":403,"errorCode":"APPATTEST_REJECTED"}"#),
            (statusCode: 403, body: #"{"statusCode":403}"#),
            (statusCode: 403, body: "Forbidden"),
        ]
    )
    func otherResponsesAreNotRecognized(statusCode: Int, body: String) {
        let error = makeMoyaError(statusCode: statusCode, body: body)

        #expect(!error.isUserWalletNotAuthorized)
    }

    @Test("A MoyaError without a response is not recognized")
    func errorWithoutResponseIsNotRecognized() {
        let error = MoyaError.underlying(URLError(.notConnectedToInternet), nil)

        #expect(!error.isUserWalletNotAuthorized)
    }

    @Test("A decoded problem detail is recognized by its status and code")
    func problemDetailIsRecognized() {
        let recognized = TangemProblemDetailError(httpStatusCode: 403, message: nil, code: "WALLET_NOT_AUTHORIZED")
        let otherCode = TangemProblemDetailError(httpStatusCode: 403, message: nil, code: "APPATTEST_REJECTED")

        #expect(recognized.isUserWalletNotAuthorized)
        #expect(!otherCode.isUserWalletNotAuthorized)
    }
}

// MARK: - Helpers

private extension ErrorUserWalletNotAuthorizedTests {
    func makeMoyaError(statusCode: Int, body: String) -> MoyaError {
        .statusCode(Response(statusCode: statusCode, data: Data(body.utf8)))
    }
}
