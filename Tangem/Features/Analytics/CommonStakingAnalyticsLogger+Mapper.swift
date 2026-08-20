//
//  CommonStakingAnalyticsLogger+Mapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNetworkUtils
import TangemStaking

private typealias CommonStakingAnalyticsMapper = CommonStakingAnalyticsLogger.Mapper

extension CommonStakingAnalyticsLogger {
    enum Mapper {
        static func map(error: any Error, currencySymbol: String) -> EventWithParameters? {
            guard !error.isCancelledRequest else { return nil }

            switch error {
            case let providerError as StakeKitHTTPError:
                return makeStakeKitEvent(for: providerError, currencySymbol: currencySymbol)

            case let providerError as P2PStakingError:
                return makeP2PEvent(for: providerError, currencySymbol: currencySymbol)

            // The P2P provider wraps its failures on the way up, so unwrap before classifying.
            case StakingAvailabilityError.dataUnavailable(let underlying):
                return map(error: underlying, currencySymbol: currencySymbol)

            default:
                return makeAppEvent(for: error, currencySymbol: currencySymbol)
            }
        }
    }
}

// MARK: - StakeKit

private extension CommonStakingAnalyticsMapper {
    static func makeStakeKitEvent(for error: StakeKitHTTPError, currencySymbol: String) -> EventWithParameters {
        var parameters = makeBaseParameters(currencySymbol: currencySymbol)
        parameters[.error] = error.errorDescription?.nilIfEmpty

        let apiError = error.apiError
        let code = apiError?.code?.nilIfEmpty
        let message = apiError?.message?.nilIfEmpty
        let path = apiError?.path?.nilIfEmpty

        guard code != nil || message != nil || path != nil else {
            parameters[.errorDescription] = stakeKitFallbackDescription(for: error)
            return EventWithParameters(event: .stakingErrors, parameters: parameters)
        }

        parameters[.errorCode] = code
        parameters[.errorMessage] = message
        parameters[.methodName] = path

        return EventWithParameters(event: .stakingErrors, parameters: parameters)
    }

    static func stakeKitFallbackDescription(for error: StakeKitHTTPError) -> String? {
        switch error {
        case .badStatusCode(let code, _, let response):
            response?.nilIfEmpty ?? "HTTP error \(code)"
        case .insufficientGasReserve:
            error.errorDescription?.nilIfEmpty
        }
    }
}

// MARK: - P2P

private extension CommonStakingAnalyticsMapper {
    /// P2P reports a failure inside a 200 response, so there is no status code to fall back on and no path to report.
    static func makeP2PEvent(for error: P2PStakingError, currencySymbol: String) -> EventWithParameters? {
        switch error {
        case .apiError(let code, let message):
            return EventWithParameters(
                event: .stakingErrors,
                parameters: makeP2PParameters(code: code, message: message, currencySymbol: currencySymbol)
            )

        case .httpError(let statusCode):
            return EventWithParameters(
                event: .stakingErrors,
                parameters: makeDescriptionParameters(description: "HTTP error \(statusCode)", currencySymbol: currencySymbol)
            )

        case .regionUnavailable:
            return EventWithParameters(
                event: .stakingErrors,
                parameters: makeDescriptionParameters(
                    description: "HTTP error \(Constants.regionUnavailableStatusCode)",
                    currencySymbol: currencySymbol
                )
            )

        case .failedToGetFee, .invalidVault, .transactionNotFound:
            return makeAppEvent(description: String(describing: error), currencySymbol: currencySymbol)

        case .feeIncreased:
            // Re-confirmation of a refreshed fee is an expected flow, not a failure.
            return nil
        }
    }

    static func makeP2PParameters(code: Int?, message: String?, currencySymbol: String) -> [Analytics.ParameterKey: String] {
        var parameters = makeBaseParameters(currencySymbol: currencySymbol)
        let message = message?.nilIfEmpty

        guard code != nil || message != nil else {
            return makeDescriptionParameters(description: Constants.unrecognizedP2PFailure, currencySymbol: currencySymbol)
        }

        parameters[.error] = message
        parameters[.errorCode] = code.map(String.init)
        parameters[.errorMessage] = message

        return parameters
    }
}

// MARK: - Private logic

private extension CommonStakingAnalyticsMapper {
    /// Everything that is not a provider failure: our own domain errors and anything we do not recognise.
    static func makeAppEvent(for error: any Error, currencySymbol: String) -> EventWithParameters {
        switch error {
        case let domainError as StakingManagerError:
            makeAppEvent(description: domainError.errorDescription, currencySymbol: currencySymbol)

        case let domainError as StakeKitMapperError:
            makeAppEvent(description: domainError.errorDescription, currencySymbol: currencySymbol)

        default:
            makeAppEvent(description: stableDescription(for: error), currencySymbol: currencySymbol)
        }
    }

    static func makeAppEvent(description: String?, currencySymbol: String) -> EventWithParameters {
        EventWithParameters(
            event: .stakingAppErrors,
            parameters: makeDescriptionParameters(description: description, currencySymbol: currencySymbol)
        )
    }

    static func makeDescriptionParameters(description: String?, currencySymbol: String) -> [Analytics.ParameterKey: String] {
        var parameters = makeBaseParameters(currencySymbol: currencySymbol)
        parameters[.error] = description?.nilIfEmpty
        parameters[.errorDescription] = description?.nilIfEmpty

        return parameters
    }

    static func makeBaseParameters(currencySymbol: String) -> [Analytics.ParameterKey: String] {
        var parameters: [Analytics.ParameterKey: String] = [:]
        parameters[.token] = currencySymbol.nilIfEmpty

        return parameters
    }

    /// Localized descriptions would split one failure into an Amplitude group per device language.
    static func stableDescription(for error: any Error) -> String {
        if let code = error.underlyingNetworkErrorCode {
            return "URLError \(code.rawValue)"
        }

        return "\(String(reflecting: type(of: error))) \(error.universalErrorCode)"
    }
}

// MARK: - Constants

private extension CommonStakingAnalyticsMapper {
    enum Constants {
        /// The P2P provider answered with an error object that carried neither a code nor a message.
        static let unrecognizedP2PFailure = "P2P API error"
        static let regionUnavailableStatusCode = 451
    }
}

// MARK: - EventWithParameters

extension CommonStakingAnalyticsMapper {
    struct EventWithParameters {
        let event: Analytics.Event
        let parameters: [Analytics.ParameterKey: String]
    }
}

// MARK: - Private helpers

private extension Error {
    var isCancelledRequest: Bool {
        isCancellationError || underlyingNetworkErrorCode == .cancelled
    }

    /// A `MoyaError` can wrap an `AFError`, and the shared lookup stops before the `URLError` inside it.
    var underlyingNetworkErrorCode: URLError.Code? {
        networkErrorCode ?? asMoyaError?.underlyingError?.networkErrorCode
    }
}
