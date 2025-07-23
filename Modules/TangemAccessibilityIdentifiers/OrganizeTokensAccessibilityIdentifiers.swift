//
//  OrganizeTokensAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum OrganizeTokensAccessibilityIdentifiers {
    public static let tokensList = "tokensList"
    public static let sortByBalanceButton = "byBalanceSortButton"
    public static let groupButton = "groupButton"
    public static let applyButton = "applyButton"

    public static func token(name: String) -> String {
        return "token_\(name)"
    }

    public static func tokenAtPosition(name: String, section: Int, item: Int) -> String {
        return "token_\(section)_\(item)_\(name)"
    }
}
