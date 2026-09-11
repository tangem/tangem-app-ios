//
//  CommonStakingAnalyticsLoggerMapperTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemStaking
@testable import Tangem

@Suite("CommonStakingAnalyticsLogger.Mapper")
struct CommonStakingAnalyticsLoggerMapperTests {
    typealias SUT = CommonStakingAnalyticsLogger.Mapper

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

    @Test("Reports a transport failure by its network code instead of a localized message", arguments: transportArguments)
    func reportsTransportFailure(error: any Error) throws {
        let entry = try map(error)

        #expect(entry.event == .stakingAppErrors)
        #expect(entry.parameters == [
            .token: Constants.token,
            .errorDescription: Constants.timedOutDetails,
            .error: Constants.timedOutDetails,
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

    @Test("Omits the token when the currency symbol is empty")
    func omitsEmptyToken() throws {
        let entry = try map(URLError(.timedOut), currencySymbol: "")

        #expect(entry.parameters == [.errorDescription: Constants.timedOutDetails, .error: Constants.timedOutDetails])
    }

    @Test("Ignores a cancelled request", arguments: cancellationArguments)
    func ignoresCancellation(error: any Error) {
        #expect(SUT.map(error: error, currencySymbol: Constants.token) == nil)
    }
}

// MARK: - Helpers

private extension CommonStakingAnalyticsLoggerMapperTests {
    /// Moya-wrapped variants would be the closest to production, but this target does not link Moya,
    /// so the double unwrapping in `underlyingNetworkErrorCode` stays covered by its comment only.
    static let transportArguments: [any Error] = [
        URLError(.timedOut),
    ]

    static let cancellationArguments: [any Error] = [
        CancellationError(),
        URLError(.cancelled),
    ]

    enum Constants {
        static let token = "SOL"

        static let timedOutDetails = "URLError -1001"

        /// A qualified type name plus the code of an error that carries no `UniversalError` conformance.
        static let decodingFailureDetails = "Swift.DecodingError -1"
    }

    func map(_ error: any Error, currencySymbol: String = Constants.token) throws -> SUT.EventWithParameters {
        try #require(SUT.map(error: error, currencySymbol: currencySymbol))
    }
}
