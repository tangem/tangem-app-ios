//
//  ManageTokensAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public enum ManageTokensAccessibilityIdentifiers {
    public static func networkToggle(_ networkName: String) -> String {
        "manageTokensNetworkToggle_\(networkName.lowercased())"
    }
}
