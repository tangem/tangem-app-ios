//
//  AddCustomTokenAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public enum AddCustomTokenAccessibilityIdentifiers {
    public static let networkSelectorRow = "addCustomToken_networkSelectorRow"
    public static let contractAddressField = "addCustomToken_contractAddressField"
    public static let derivationSelectorRow = "addCustomToken_derivationSelectorRow"
    public static let addButton = "addCustomToken_addButton"
    public static let derivationPathField = "addCustomToken_derivationPathField"
    public static let derivationPathSaveButton = "addCustomToken_derivationPathSaveButton"
    public static let warningNotification = "addCustomToken_warningNotification"

    public static func networkRow(_ networkName: String) -> String {
        "addCustomToken_networkRow_\(networkName.lowercased())"
    }

    public static func derivationOptionRow(_ optionId: String) -> String {
        "addCustomToken_derivationOption_\(optionId.lowercased())"
    }
}
