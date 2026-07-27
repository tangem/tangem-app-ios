//
//  Error+MarketsAnalyticsParams.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Alamofire

extension Error {
    var marketsAnalyticsParams: [Analytics.ParameterKey: String] {
        var analyticsParams = [Analytics.ParameterKey: String]()

        analyticsParams[.errorMessage] = localizedDescription
        analyticsParams[.errorCode] = marketsErrorCode
        analyticsParams[.errorType] = marketsErrorType.rawValue

        return analyticsParams
    }

    private var marketsErrorCode: String {
        if let moyaError = self as? MoyaError,
           case .statusCode(let response) = moyaError {
            return String(response.statusCode)
        } else {
            return Analytics.ParameterValue.marketsErrorCodeIsNotHTTPError.rawValue
        }
    }

    private var marketsErrorType: Analytics.ParameterValue {
        switch self {
        case _ as MarketsTokenHistoryChartMapper.ParsingError:
            return .custom
        case let moyaError as MoyaError where moyaError.isStatusCodeError:
            return .marketsErrorTypeHTTP
        case let moyaError as MoyaError:
            guard let underlyingError = moyaError.underlyingError else {
                fallthrough
            }
            return marketsErrorType(forUnderlyingMoyaError: underlyingError)
        default:
            return .unknown
        }
    }

    private func marketsErrorType(forUnderlyingMoyaError error: Error) -> Analytics.ParameterValue {
        if let afError = error as? AFError,
           case .sessionTaskFailed(let urlError as URLError) = afError,
           urlError.code == .timedOut {
            return .marketsErrorTypeTimeout
        }

        return .marketsErrorTypeNetwork
    }
}

private extension MoyaError {
    var underlyingError: Error? {
        switch self {
        case .underlying(let error, _): error
        default: nil
        }
    }

    var isStatusCodeError: Bool {
        switch self {
        case .statusCode: true
        default: false
        }
    }
}
