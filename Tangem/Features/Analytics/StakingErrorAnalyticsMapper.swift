//
//  StakingErrorAnalyticsMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNetworkUtils
import TangemStaking

enum StakingErrorAnalyticsMapper {
    static func map(error: any Error, currencySymbol: String) -> Entry? {
        guard !error.isCancellationError, networkErrorCode(for: error) != .cancelled else {
            return nil
        }

        switch error {
        case let providerError as StakeKitHTTPError:
            return Entry(
                event: .stakingErrors,
                parameters: providerParameters(for: providerError, currencySymbol: currencySymbol)
            )

        case let domainError as LocalizedError where domainError is StakingManagerError || domainError is StakeKitMapperError:
            return Entry(
                event: .stakingAppErrors,
                parameters: appParameters(description: domainError.errorDescription, currencySymbol: currencySymbol)
            )

        default:
            return Entry(
                event: .stakingAppErrors,
                parameters: appParameters(description: stableDescription(for: error), currencySymbol: currencySymbol)
            )
        }
    }
}

// MARK: - Private logic

private extension StakingErrorAnalyticsMapper {
    static func providerParameters(for error: StakeKitHTTPError, currencySymbol: String) -> [Analytics.ParameterKey: String] {
        var parameters = baseParameters(currencySymbol: currencySymbol)
        parameters[.error] = error.errorDescription?.nilIfEmpty

        let apiError = error.apiError
        let code = apiError?.code?.nilIfEmpty
        let message = apiError?.message?.nilIfEmpty
        let path = apiError?.path?.nilIfEmpty

        guard code != nil || message != nil || path != nil else {
            parameters[.errorDescription] = fallbackDescription(for: error)
            return parameters
        }

        parameters[.errorCode] = code
        parameters[.errorMessage] = message
        parameters[.methodName] = path

        return parameters
    }

    static func fallbackDescription(for error: StakeKitHTTPError) -> String? {
        switch error {
        case .badStatusCode(let code, _, let response):
            response?.nilIfEmpty ?? "HTTP error \(code)"
        case .insufficientGasReserve:
            error.errorDescription?.nilIfEmpty
        }
    }

    static func appParameters(description: String?, currencySymbol: String) -> [Analytics.ParameterKey: String] {
        var parameters = baseParameters(currencySymbol: currencySymbol)
        parameters[.error] = description?.nilIfEmpty
        parameters[.errorDescription] = description?.nilIfEmpty

        return parameters
    }

    static func baseParameters(currencySymbol: String) -> [Analytics.ParameterKey: String] {
        var parameters: [Analytics.ParameterKey: String] = [:]
        parameters[.token] = currencySymbol.nilIfEmpty

        return parameters
    }

    /// Localized descriptions would split one failure into an Amplitude group per device language.
    static func stableDescription(for error: any Error) -> String {
        if let code = networkErrorCode(for: error) {
            return "URLError \(code.rawValue)"
        }

        return "\(String(reflecting: type(of: error))) \(error.universalErrorCode)"
    }

    /// A `MoyaError` can wrap an `AFError`, and the shared lookup stops before the `URLError` inside it.
    static func networkErrorCode(for error: any Error) -> URLError.Code? {
        error.networkErrorCode ?? error.asMoyaError?.underlyingError?.networkErrorCode
    }
}

// MARK: - Entry

extension StakingErrorAnalyticsMapper {
    struct Entry: Equatable {
        let event: Analytics.Event
        let parameters: [Analytics.ParameterKey: String]
    }
}
