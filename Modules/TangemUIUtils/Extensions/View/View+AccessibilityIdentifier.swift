//
//  View+AccessibilityIdentifier.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Sets the accessibility identifier for the view if the provided value is not nil
    /// - Parameter identifier: The optional accessibility identifier to set
    /// - Returns: The modified view
    func accessibilityIdentifier(_ identifier: String?) -> some View {
        modifier(AccessibilityIdentifierModifier(identifier: identifier))
    }
}

private struct AccessibilityIdentifierModifier: ViewModifier {
    let identifier: String?

    func body(content: Content) -> some View {
        if let identifier = identifier {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}
