//
//  SelectionControlSize.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public enum SelectionControlSize: Sendable, Hashable, CaseIterable {
    case size24
    case size20

    var side: CGFloat {
        switch self {
        case .size24: 24
        case .size20: 20
        }
    }
}

struct SelectionControlGlyph {
    let size24: ImageType
    let size20: ImageType

    func image(for size: SelectionControlSize) -> ImageType {
        switch size {
        case .size24: size24
        case .size20: size20
        }
    }
}

extension SelectionControlGlyph {
    static let boxRegular = SelectionControlGlyph(
        size24: DesignSystem.Icons.ControlBox.regular24,
        size20: DesignSystem.Icons.ControlBox.regular20
    )

    static let boxFilled = SelectionControlGlyph(
        size24: DesignSystem.Icons.ControlBox.filled24,
        size20: DesignSystem.Icons.ControlBox.filled20
    )

    static let circleRegular = SelectionControlGlyph(
        size24: DesignSystem.Icons.ControlCircle.regular24,
        size20: DesignSystem.Icons.ControlCircle.regular20
    )

    static let circleFilled = SelectionControlGlyph(
        size24: DesignSystem.Icons.ControlCircle.filled24,
        size20: DesignSystem.Icons.ControlCircle.filled20
    )

    static let checkmark = SelectionControlGlyph(
        size24: DesignSystem.Icons.ControlCheckmark.regular24,
        size20: DesignSystem.Icons.ControlCheckmark.regular20
    )

    static let indeterminate = SelectionControlGlyph(
        size24: DesignSystem.Icons.ControlIndeterminate.regular24,
        size20: DesignSystem.Icons.ControlIndeterminate.regular20
    )
}
