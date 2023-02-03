//
//  ABIError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum ABIError: String, LocalizedError {
    case integerOverflow
    case invalidUTF8String
    case invalidNumberOfArguments
    case invalidArgumentType
    case functionSignatureMismatch

    public var errorDescription: String? {
        return rawValue
    }
}
