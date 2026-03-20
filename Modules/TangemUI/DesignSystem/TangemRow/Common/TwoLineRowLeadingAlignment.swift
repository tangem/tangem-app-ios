//
//  TwoLineRowLeadingAlignment.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension HorizontalAlignment {
    /// Leading edge of the primary content slot in `TangemTwoLineRowLayout`.
    /// Used to align external elements (e.g. callout arrows) with the token name's leading edge.
    static let twoLineRowLeading = HorizontalAlignment(TwoLineRowLeadingAlignmentID.self)
}

private enum TwoLineRowLeadingAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[HorizontalAlignment.leading]
    }
}
