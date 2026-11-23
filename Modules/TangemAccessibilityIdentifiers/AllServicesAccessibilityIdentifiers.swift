//
//  AllServicesAccessibilityIdentifiers.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum AllServicesAccessibilityIdentifiers {
    public static let referralButton = "allServicesReferralButton"

    public static func item(_ id: String) -> String {
        "allServicesItem_\(id)"
    }
}
