//
//  View+Accessibility.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Uses the string you specify to identify the view.
    ///
    /// Use this value for testing. It isn't visible to the user.
    ///
    /// - Note: This is a convenience overload of ``View/accessibilityIdentifier(_:)`` that accepts an optional value.
    @ViewBuilder @_disfavoredOverload
    func accessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }

    /// Adds a label to the view that describes its contents.
    ///
    /// Use this method to provide an accessibility label for a view that doesn't display text, like an icon.
    /// For example, you could use this method to label a button that plays music with the text "Play".
    /// Don't include text in the label that repeats information that users already have. For example,
    /// don't use the label "Play button" because a button already has a trait that identifies it as a button.
    ///
    /// - Note: This is a convenience overload of ``View/accessibilityLabel(_:)`` that accepts an optional value.
    @ViewBuilder @_disfavoredOverload
    func accessibilityLabel(_ label: String?) -> some View {
        if let label {
            accessibilityLabel(label)
        } else {
            self
        }
    }
}
