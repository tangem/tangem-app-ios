//
//  CommonStakingAnalyticsLoggerMapperStakeKitTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemStaking
@testable import Tangem

@Suite("CommonStakingAnalyticsLogger.Mapper + StakeKit")
struct CommonStakingAnalyticsLoggerMapperStakeKitTests {
    typealias SUT = CommonStakingAnalyticsLogger.Mapper

    @Test("Reports the code, the message and the failing method read from the error body", arguments: decodedBodyArguments)
    func reportsDecodedBody(error: StakeKitHTTPError, expectedLegacyDescription: String) throws {
        let entry = try map(error)

        #expect(entry.event == .stakingErrors)
        #expect(entry.parameters == Constants.decodedBodyParameters(legacyDescription: expectedLegacyDescription))
    }

    @Test("Falls back to the response body, and to the status code when there is none", arguments: fallbackArguments)
    func fallsBackWhenBodyWasNotDecoded(response: String?, expectedDetails: String, expectedLegacy: String?) throws {
        let error = StakeKitHTTPError.badStatusCode(code: 502, apiError: nil, response: response)

        let entry = try map(error)

        var expected: [Analytics.ParameterKey: String] = [.token: Constants.token, .errorDescription: expectedDetails]
        expected[.error] = expectedLegacy

        #expect(entry.event == .stakingErrors)
        #expect(entry.parameters == expected)
    }

    @Test("Falls back to the built-in description when an insufficient gas reserve carries no usable body")
    func fallsBackForInsufficientGasReserve() throws {
        let error = StakeKitHTTPError.insufficientGasReserve(
            shortfallAmount: 0.000005,
            gasTokenSymbol: Constants.token,
            apiError: Constants.bodyWithoutFields
        )

        let entry = try map(error)

        let details = "Insufficient \(Constants.token) for gas: shortfall 0.000005"

        #expect(entry.event == .stakingErrors)
        #expect(entry.parameters == [.token: Constants.token, .errorDescription: details, .error: details])
    }

    @Test("Falls back to the response body when the decoded one carries nothing usable")
    func fallsBackWhenDecodedBodyIsUnusable() throws {
        let body = #"{"unexpected": true}"#
        let error = StakeKitHTTPError.badStatusCode(
            code: 400,
            apiError: try decodeAPIError(from: body),
            response: body
        )

        let entry = try map(error)

        #expect(entry.parameters == [.token: Constants.token, .errorDescription: body, .error: body])
    }
}

// MARK: - Helpers

private extension CommonStakingAnalyticsLoggerMapperStakeKitTests {
    /// Both cases carry a decoded body, and only the legacy description differs.
    static let decodedBodyArguments: [(error: StakeKitHTTPError, expectedLegacyDescription: String)] = [
        (
            error: .badStatusCode(code: 412, apiError: Constants.apiError, response: Constants.body),
            expectedLegacyDescription: Constants.message
        ),
        (
            error: .insufficientGasReserve(
                shortfallAmount: 0.000005,
                gasTokenSymbol: Constants.token,
                apiError: Constants.apiError
            ),
            expectedLegacyDescription: "Insufficient \(Constants.token) for gas: shortfall 0.000005"
        ),
    ]

    static let fallbackArguments: [(response: String?, expectedDetails: String, expectedLegacy: String?)] = [
        (
            response: "<html>502 Bad Gateway</html>",
            expectedDetails: "<html>502 Bad Gateway</html>",
            expectedLegacy: "<html>502 Bad Gateway</html>"
        ),
        (response: "", expectedDetails: "HTTP error 502", expectedLegacy: nil),
        (response: nil, expectedDetails: "HTTP error 502", expectedLegacy: "HTTP error 502"),
    ]

    enum Constants {
        static let token = "SOL"
        static let code = "412"
        static let message = "Insufficient balance for gas fees"
        static let path = "/v1/actions/enter/estimate-gas"

        static let body = """
        {
            "message": "\(message)",
            "code": \(code),
            "path": "\(path)"
        }
        """

        static let apiError = try! JSONDecoder().decode(StakeKitAPIError.self, from: Data(body.utf8))

        /// A gas-reserve body carries only `details`, so the triple stays empty and the mapper has to fall back.
        static let bodyWithoutFields = try! JSONDecoder().decode(
            StakeKitAPIError.self,
            from: Data(#"{"details": {"code": "INSUFFICIENT_GAS_RESERVE"}}"#.utf8)
        )

        static func decodedBodyParameters(legacyDescription: String) -> [Analytics.ParameterKey: String] {
            [
                .token: token,
                .errorCode: code,
                .errorMessage: message,
                .methodName: path,
                .error: legacyDescription,
            ]
        }
    }

    func map(_ error: any Error, currencySymbol: String = Constants.token) throws -> SUT.EventWithParameters {
        try #require(SUT.map(error: error, currencySymbol: currencySymbol))
    }

    func decodeAPIError(from json: String) throws -> StakeKitAPIError {
        try JSONDecoder().decode(StakeKitAPIError.self, from: Data(json.utf8))
    }
}
