//
//  Error+networkErrorCode.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Alamofire

public extension Error {
    var networkErrorCode: URLError.Code? {
        let urlErrorCode = (self as? URLError)?.code
        let afErrorCode = (asAFError?.underlyingError as? URLError)?.code
        let moyaErrorCode = (asMoyaError?.underlyingError as? URLError)?.code

        return urlErrorCode ?? afErrorCode ?? moyaErrorCode
    }
}
