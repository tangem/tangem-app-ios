//
//  MoyaError+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
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

    var urlError: URLError? {
        underlyingError as? URLError
    }
}
