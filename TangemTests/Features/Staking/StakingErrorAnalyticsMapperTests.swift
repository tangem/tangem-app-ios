//
//  StakingErrorAnalyticsMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemStaking
@testable import Tangem

@Suite("StakingErrorAnalyticsMapper")
struct StakingErrorAnalyticsMapperTests {
    typealias SUT = StakingErrorAnalyticsMapper

    // MARK: - Provider errors

    @Test("Reports the code, the message and the failing method read from the error body")
    func reportsDecodedBody() throws {
        let error = StakeKitHTTPError.badStatusCode(
            code: 412,
            apiError: try makeAPIError(),
            response: Constants.body
        )

        let entry = try map(error)

        #expect(entry.event == .stakingErrors)
        #expect(entry.parameters == Constants.decodedBodyParameters(legacyDescription: Constants.message))
    }

    @Test("Reports an insufficient gas reserve as a regular provider failure")
    func reportsInsufficientGasReserve() throws {
        let error = StakeKitHTTPError.insufficientGasReserve(
            shortfallAmount: 0.000005,
            gasTokenSymbol: Constants.token,
            apiError: try makeAPIError()
        )

        let entry = try map(error)

        let expected = Constants.decodedBodyParameters(
            legacyDescription: "Insufficient \(Constants.token) for gas: shortfall 0.000005"
        )

        #expect(entry.event == .stakingErrors)
        #expect(entry.parameters == expected)
    }

    private static let fallbackArguments: [(response: String?, expectedDetails: String, expectedLegacy: String?)] = [
        (response: "<html>502 Bad Gateway</html>", expectedDetails: "<html>502 Bad Gateway</html>", expectedLegacy: "<html>502 Bad Gateway</html>"),
        (response: "", expectedDetails: "HTTP error 502", expectedLegacy: nil),
        (response: nil, expectedDetails: "HTTP error 502", expectedLegacy: "HTTP error 502"),
    ]

    @Test("Falls back to the response body, and to the status code when there is none", arguments: fallbackArguments)
    func fallsBackWhenBodyWasNotDecoded(response: String?, expectedDetails: String, expectedLegacy: String?) throws {
        let error = StakeKitHTTPError.badStatusCode(code: 502, apiError: nil, response: response)

        let entry = try map(error)

        var expected: [Analytics.ParameterKey: String] = [.token: Constants.token, .errorDescription: expectedDetails]
        expected[.error] = expectedLegacy

        #expect(entry.event == .stakingErrors)
        #expect(entry.parameters == expected)
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

    @Test("Omits the token when the currency symbol is empty")
    func omitsEmptyToken() throws {
        let error = StakeKitHTTPError.badStatusCode(code: 502, apiError: nil, response: nil)

        let entry = try map(error, currencySymbol: "")

        #expect(entry.parameters == [.errorDescription: "HTTP error 502", .error: "HTTP error 502"])
    }

    // MARK: - App errors

    @Test("Reports a mapping failure as an app error")
    func reportsMappingFailure() throws {
        let entry = try map(StakeKitMapperError.noData("No validators"), currencySymbol: "TRX")

        #expect(entry.event == .stakingAppErrors)
        #expect(
            entry.parameters == [
                .token: "TRX",
                .errorDescription: "No validators",
                .error: "No validators",
            ]
        )
    }

    @Test("Reports a transport failure by its network code instead of a localized message")
    func reportsTransportFailure() throws {
        let error = URLError(.timedOut)

        let entry = try map(error)

        #expect(entry.event == .stakingAppErrors)
        #expect(entry.parameters == [
            .token: Constants.token,
            .errorDescription: "URLError \(URLError.Code.timedOut.rawValue)",
            .error: "URLError \(URLError.Code.timedOut.rawValue)",
        ])
    }

    @Test("Reports a decoding failure by its type instead of a localized message")
    func reportsDecodingFailure() throws {
        let error = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Broken payload"))

        let entry = try map(error)

        #expect(entry.event == .stakingAppErrors)
        #expect(entry.parameters[.token] == Constants.token)
        #expect(entry.parameters[.errorDescription] == Constants.decodingFailureDetails)
        #expect(entry.parameters[.error] == Constants.decodingFailureDetails)
    }

    // MARK: - Cancellation

    @Test("Ignores a cancelled request")
    func ignoresCancellation() {
        #expect(SUT.map(error: CancellationError(), currencySymbol: Constants.token) == nil)
        #expect(SUT.map(error: URLError(.cancelled), currencySymbol: Constants.token) == nil)
    }
}

// MARK: - Helpers

private extension StakingErrorAnalyticsMapperTests {
    enum Constants {
        static let token = "SOL"
        static let code = "412"
        static let message = "Insufficient balance for gas fees"
        static let path = "/v1/actions/enter/estimate-gas"

        /// A qualified type name plus the code of an error that carries no `UniversalError` conformance.
        static let decodingFailureDetails = "Swift.DecodingError -1"

        static let body = """
        {
            "message": "\(message)",
            "code": \(code),
            "path": "\(path)"
        }
        """

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

    func map(_ error: any Error, currencySymbol: String = Constants.token) throws -> SUT.Entry {
        try #require(SUT.map(error: error, currencySymbol: currencySymbol))
    }

    func makeAPIError() throws -> StakeKitAPIError {
        try decodeAPIError(from: Constants.body)
    }

    func decodeAPIError(from json: String) throws -> StakeKitAPIError {
        try JSONDecoder().decode(StakeKitAPIError.self, from: Data(json.utf8))
    }
}
