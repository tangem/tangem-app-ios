//
//  RowAccessibility.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

enum RowAccessibility {
    enum Shape {
        case element(label: String?)
        case container
    }
}

extension View {
    func rowAccessibility(label: String?, hint: String? = nil, isSelected: Bool = false) -> some View {
        rowAccessibility(RowAccessibility.Shape.element(label: label), hint: hint, isSelected: isSelected)
    }

    @ViewBuilder
    func rowAccessibility(_ shape: RowAccessibility.Shape, hint: String? = nil, isSelected: Bool = false) -> some View {
        let traits: AccessibilityTraits = isSelected ? .isSelected : []

        switch shape {
        case .element(.some(let label)):
            accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .rowAccessibilityHint(hint)
                .accessibilityAddTraits(traits)

        case .element(.none):
            accessibilityElement(children: .combine)
                .rowAccessibilityHint(hint)
                .accessibilityAddTraits(traits)

        case .container:
            accessibilityElement(children: .contain)
                .rowAccessibilityHint(hint)
                .accessibilityAddTraits(traits)
        }
    }

    @ViewBuilder
    private func rowAccessibilityHint(_ hint: String?) -> some View {
        if let hint {
            accessibilityHint(hint)
        } else {
            self
        }
    }
}
