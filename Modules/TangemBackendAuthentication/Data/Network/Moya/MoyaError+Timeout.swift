//
//  MoyaError+Timeout.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import struct Foundation.URLError
private import enum Alamofire.AFError
import enum Moya.MoyaError

extension MoyaError {
    var isTimeout: Bool {
        guard
            case .underlying(let underlyingError, _) = self,
            case .sessionTaskFailed(let sessionTaskError) = underlyingError as? AFError,
            let urlError = sessionTaskError as? URLError
        else {
            return false
        }

        return urlError.code == URLError.Code.timedOut
    }
}
