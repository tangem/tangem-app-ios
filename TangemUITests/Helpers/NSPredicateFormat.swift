//
//  NSPredicateFormat.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum NSPredicateFormat: String {
    case exists = "exists == 1"
    case doesntExist = "exists == 0"
    case enabled = "isEnabled == 1"
    case hittable = "isHittable == 1"
    case labelContains = "label CONTAINS[c] %@"
    case identifierContains = "identifier CONTAINS %@"
}
