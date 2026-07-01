//
//  ManageTokensAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public enum ManageTokensAccessibilityIdentifiers {
    public static let saveButton = "manageTokens_saveButton"
    public static let searchField = "manageTokens_searchField"

    public static func coinRow(_ coinId: String) -> String {
        "manageTokens_coinRow_\(coinId)"
    }

    public static func networkToggle(_ networkName: String) -> String {
        "manageTokensNetworkToggle_\(networkName.lowercased())"
    }

    public static func networkStandardLabel(_ networkName: String) -> String {
        "manageTokens_networkStandard_\(networkName.lowercased())"
    }
}
