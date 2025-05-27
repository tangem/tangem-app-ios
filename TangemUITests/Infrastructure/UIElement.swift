//
//  UIElement.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

protocol UIElement {
    var accessibilityIdentifier: String { get }
}

extension UIElement where Self: RawRepresentable {
    var accessibilityIdentifier: RawValue {
        rawValue
    }
}
