//
//  MoyaError+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Alamofire
import Moya

public extension MoyaError {
    /// Just a copy-paste from MoyaError.swift (it has `internal` access level)
    var underlyingError: Swift.Error? {
        switch self {
        case .imageMapping,
             .jsonMapping,
             .stringMapping,
             .requestMapping,
             .statusCode:
            return nil
        case .objectMapping(let error, _):
            return error
        case .encodableMapping(let error):
            return error
        case .underlying(let error, _):
            return error
        case .parameterEncoding(let error):
            return error
        }
    }

    var isTooManyRequests: Bool {
        if case .statusCode(let response) = self {
            return response.statusCode == 429
        }
        return false
    }

    /// What the host answered when it rejected the request, for logs that have to say why a node was skipped.
    var unsuccessfulResponseBody: String? {
        guard case .statusCode(let response) = self else {
            return nil
        }

        return String(data: response.data, encoding: .utf8) ?? "no response data"
    }

    var isTimeout: Bool {
        urlErrorCode == .timedOut
    }

    var isNotConnectedToInternet: Bool {
        guard let urlErrorCode else {
            return false
        }

        return [.notConnectedToInternet, .dataNotAllowed, .networkConnectionLost].contains(urlErrorCode)
    }

    var isMappingError: Bool {
        switch self {
        case .objectMapping,
             .encodableMapping,
             .imageMapping,
             .jsonMapping,
             .stringMapping,
             .requestMapping,
             .parameterEncoding:
            return true
        case .statusCode,
             .underlying:
            return false
        }
    }
}

private extension MoyaError {
    var urlErrorCode: URLError.Code? {
        guard
            case .underlying(let underlyingError, _) = self,
            case .sessionTaskFailed(let sessionTaskError) = underlyingError as? AFError,
            let urlError = sessionTaskError as? URLError
        else {
            return nil
        }

        return urlError.code
    }
}
