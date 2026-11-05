//
//  CommonExpressAPIServiceStatusCodeRejectionTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Alamofire
import Foundation
import Testing
import TangemFoundation
@testable import TangemExpress

@Suite("Express API service — which failed requests carry a response to map")
struct CommonExpressAPIServiceStatusCodeRejectionTests {
    @Test("A refused status code is mapped, also when the session renewal before the retry failed", arguments: Constants.rejections)
    func statusCodeRejectionIsMapped(error: any Error) {
        #expect(CommonExpressAPIService.isStatusCodeRejection(error))
    }

    @Test("A network failure stays a network failure, even when the headers had already arrived", arguments: Constants.networkFailures)
    func networkFailureIsNotMapped(error: any Error) {
        #expect(!CommonExpressAPIService.isStatusCodeRejection(error))
    }
}

// MARK: - Helpers

private extension CommonExpressAPIServiceStatusCodeRejectionTests {
    enum Constants {
        static let unauthorized = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))

        static let rejections: [any Error] = [
            unauthorized,
            AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 400)),
            AFError.requestRetryFailed(retryError: NSError.dummy, originalError: unauthorized),
        ]

        static let networkFailures: [any Error] = [
            AFError.sessionTaskFailed(error: URLError(.networkConnectionLost)),
            AFError.requestRetryFailed(retryError: NSError.dummy, originalError: AFError.sessionTaskFailed(error: URLError(.timedOut))),
            URLError(.notConnectedToInternet),
        ]
    }
}
