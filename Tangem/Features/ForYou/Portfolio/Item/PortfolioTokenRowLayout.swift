//
//  PortfolioTokenRowLayout.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics

/// Shared geometry for portfolio token rows. The loading shimmer and the resolved content read the same
/// constants, so a row keeps its icon size, spacing and padding when it resolves — nothing shifts.
enum PortfolioTokenRowLayout {
    static let iconSize: CGFloat = 40
    static let horizontalSpacing: CGFloat = 12
    static let verticalSpacing: CGFloat = 4
    static let contentPadding: CGFloat = 16
}
