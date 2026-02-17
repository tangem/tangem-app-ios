//
//  TangemRowCompressionPolicy.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Defines how content should be compressed when space is limited in a two-line row layout.
public enum TangemRowCompressionPolicy {
    /// Trailing content (e.g., balances) has highest priority and compresses last.
    /// This is the default policy for token rows where balance display is prioritized.
    case trailingPreserved

    /// Leading content (e.g., name/title) has highest priority and compresses last.
    case leadingPreserved

    /// All content has equal compression priority.
    case balanced

    /// Custom priorities for fine-grained control.
    case custom(TangemRowCompressionPriorities)

    var priorities: TangemRowCompressionPriorities {
        switch self {
        case .trailingPreserved:
            return .trailingPreserved
        case .leadingPreserved:
            return .leadingPreserved
        case .balanced:
            return .balanced
        case .custom(let priorities):
            return priorities
        }
    }
}

/// Layout priorities for each slot in a two-line row.
/// Higher values mean the content compresses later (is preserved longer).
public struct TangemRowCompressionPriorities: Equatable {
    public let primaryLeading: Double
    public let primaryTrailing: Double
    public let secondaryLeading: Double
    public let secondaryTrailing: Double

    public init(
        primaryLeading: Double,
        primaryTrailing: Double,
        secondaryLeading: Double,
        secondaryTrailing: Double
    ) {
        self.primaryLeading = primaryLeading
        self.primaryTrailing = primaryTrailing
        self.secondaryLeading = secondaryLeading
        self.secondaryTrailing = secondaryTrailing
    }

    /// Default priorities: trailing content is preserved (compresses last).
    /// Matches the current TangemTokenRow behavior.
    public static let `default` = TangemRowCompressionPriorities(
        primaryLeading: 1,
        primaryTrailing: 3,
        secondaryLeading: 2,
        secondaryTrailing: 3
    )

    /// Trailing content (balances) has highest priority.
    public static let trailingPreserved = TangemRowCompressionPriorities(
        primaryLeading: 1,
        primaryTrailing: 3,
        secondaryLeading: 2,
        secondaryTrailing: 3
    )

    /// Leading content (name/title) has highest priority.
    public static let leadingPreserved = TangemRowCompressionPriorities(
        primaryLeading: 3,
        primaryTrailing: 1,
        secondaryLeading: 3,
        secondaryTrailing: 2
    )

    /// All content has equal priority.
    public static let balanced = TangemRowCompressionPriorities(
        primaryLeading: 1,
        primaryTrailing: 1,
        secondaryLeading: 1,
        secondaryTrailing: 1
    )
}
