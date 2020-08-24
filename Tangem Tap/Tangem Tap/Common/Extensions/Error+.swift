//
//  Error+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

extension Error {
    var detailedError: Error {
        if case let .underlying(uError, _) = self as? MoyaError,
            case let .sessionTaskFailed(sessionError) = uError.asAFError {
            return sessionError
        } else {
            return self
        }
    }
}
