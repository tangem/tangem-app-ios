//
//  CommonStakingAnalyticsLoggerMapperP2PTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemStaking
@testable import Tangem

@Suite("CommonStakingAnalyticsLogger.Mapper + P2P")
struct CommonStakingAnalyticsLoggerMapperP2PTests {
    typealias SUT = CommonStakingAnalyticsLogger.Mapper

    @Test("Reports the code and the message read from the error body")
    func reportsDecodedBody() throws {
        let error = P2PStakingError.apiError(code: 127102, message: Constants.message)

        let entry = try map(error)

        #expect(entry.event == .stakingErrors)
        #expect(
            entry.parameters == [
                .token: Constants.token,
                .errorCode: "127102",
                .errorMessage: Constants.message,
                .error: Constants.message,
            ]
        )
    }

    @Test("Reports a code that arrived without a message")
    func reportsCodeWithoutMessage() throws {
        let entry = try map(P2PStakingError.apiError(code: 127102, message: nil))

        #expect(entry.event == .stakingErrors)
        #expect(entry.parameters == [.token: Constants.token, .errorCode: "127102"])
    }

    @Test("Falls back to a marker when the error body carries neither a code nor a message")
    func fallsBackWhenBodyIsUnusable() throws {
        let entry = try map(P2PStakingError.apiError(code: nil, message: nil))

        #expect(entry.event == .stakingErrors)
        #expect(
            entry.parameters == [
                .token: Constants.token,
                .errorDescription: Constants.unrecognizedFailure,
                .error: Constants.unrecognizedFailure,
            ]
        )
    }

    @Test("Reports a status-only failure as a provider failure", arguments: statusArguments)
    func reportsStatusOnlyFailure(error: P2PStakingError, expectedDetails: String) throws {
        let entry = try map(error)

        #expect(entry.event == .stakingErrors)
        #expect(
            entry.parameters == [
                .token: Constants.token,
                .errorDescription: expectedDetails,
                .error: expectedDetails,
            ]
        )
    }

    @Test("Unwraps a failure reported through the availability error")
    func unwrapsWrappedFailure() throws {
        let wrapped = StakingAvailabilityError.dataUnavailable(
            underlying: P2PStakingError.apiError(code: 124108, message: Constants.message)
        )

        let entry = try map(wrapped)

        #expect(entry.event == .stakingErrors)
        #expect(
            entry.parameters == [
                .token: Constants.token,
                .errorCode: "124108",
                .errorMessage: Constants.message,
                .error: Constants.message,
            ]
        )
    }

    @Test("Unwraps a transport failure reported through the availability error")
    func unwrapsWrappedTransportFailure() throws {
        let wrapped = StakingAvailabilityError.dataUnavailable(underlying: URLError(.notConnectedToInternet))

        let entry = try map(wrapped)

        #expect(entry.event == .stakingAppErrors)
        #expect(
            entry.parameters == [
                .token: Constants.token,
                .errorDescription: "URLError -1009",
                .error: "URLError -1009",
            ]
        )
    }

    @Test("Reports a state failure as an app error", arguments: stateArguments)
    func reportsStateFailure(error: P2PStakingError, expectedDescription: String) throws {
        let entry = try map(error)

        #expect(entry.event == .stakingAppErrors)
        #expect(
            entry.parameters == [
                .token: Constants.token,
                .errorDescription: expectedDescription,
                .error: expectedDescription,
            ]
        )
    }

    @Test("Ignores a refreshed fee that only needs re-confirmation")
    func ignoresIncreasedFee() {
        #expect(SUT.map(error: P2PStakingError.feeIncreased(newFee: 0.01), currencySymbol: Constants.token) == nil)
    }
}

// MARK: - Helpers

private extension CommonStakingAnalyticsLoggerMapperP2PTests {
    static let stateArguments: [(error: P2PStakingError, expectedDescription: String)] = [
        (error: .failedToGetFee, expectedDescription: "failedToGetFee"),
        (error: .invalidVault, expectedDescription: "invalidVault"),
        (error: .transactionNotFound, expectedDescription: "transactionNotFound"),
    ]

    static let statusArguments: [(error: P2PStakingError, expectedDetails: String)] = [
        (error: .httpError(statusCode: 502), expectedDetails: "HTTP error 502"),
        (error: .regionUnavailable, expectedDetails: "HTTP error 451"),
    ]

    enum Constants {
        static let token = "ETH"
        static let message = "Insufficient account balance"
        static let unrecognizedFailure = "P2P API error"
    }

    func map(_ error: any Error, currencySymbol: String = Constants.token) throws -> SUT.EventWithParameters {
        try #require(SUT.map(error: error, currencySymbol: currencySymbol))
    }
}
