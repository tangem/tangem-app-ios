//
//  TangemSearch+Modifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUIUtils

// MARK: - Setupable setters

public extension TangemSearch {
    func placeholder(_ text: String) -> Self {
        map { $0.placeholderText = text }
    }

    func showsCloseButton(_ shows: Bool) -> Self {
        map { $0.showsCloseButton = shows }
    }

    func interactiveGlass(_ enabled: Bool) -> Self {
        map { $0.interactiveGlass = enabled }
    }

    func containerAccessibilityIdentifier(_ identifier: String?) -> Self {
        map { $0.containerAccessibilityIdentifier = identifier }
    }

    func textFieldAccessibilityIdentifier(_ identifier: String?) -> Self {
        map { $0.textFieldAccessibilityIdentifier = identifier }
    }

    func clearButtonAccessibilityIdentifier(_ identifier: String?) -> Self {
        map { $0.clearButtonAccessibilityIdentifier = identifier }
    }

    func closeButtonAccessibilityIdentifier(_ identifier: String?) -> Self {
        map { $0.closeButtonAccessibilityIdentifier = identifier }
    }
}
