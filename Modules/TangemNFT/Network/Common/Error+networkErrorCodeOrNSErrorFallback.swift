//
//  Error+networkErrorCodeOrNSErrorFallback.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

extension Error {
    var networkErrorCodeOrNSErrorFallback: Int {
        networkErrorCode?.rawValue ?? (self as NSError).code
    }
}
