//
//  AlephiumError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum AlephiumError: Error {
    case negativeDuration
    case alphAmountOverflow
    case runtime(String)
    case txOutputValueTooSmall
    case tokenValuesMustBeNonZero
}
