//
//  MoyaError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Moya

public extension Error {
    var asMoyaError: MoyaError? {
        self as? MoyaError
    }
}
