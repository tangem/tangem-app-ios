//
//  ModalContentLayout.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum ModalContentLayout: Hashable, Sendable {
    /// Fits the content and scrolls it when the available height is smaller.
    case scrollable

    /// Fits short, non-scrolling content. Use `scrollable` if it can exceed the available height.
    case intrinsic

    /// Gives a caller-managed List or ScrollView a viewport: half-height for Flexible, full-height for Full.
    case fill
}
