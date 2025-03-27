//
//  FloatingSheetConfiguration.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct FloatingSheetConfiguration {
    public var minHeightFraction: CGFloat
    public var maxHeightFraction: CGFloat
    public var sheetBackgroundColor: Color
    public var backgroundInteractionBehavior: BackgroundInteractionBehavior
    public var verticalSwipeBehavior: VerticalSwipeBehavior?
    public var keyboardHandlingEnabled: Bool
}

extension FloatingSheetConfiguration {
    var isBackgroundSwipeEnabled: Bool {
        verticalSwipeBehavior?.target == .background
    }

    var isSheetSwipeEnabled: Bool {
        verticalSwipeBehavior?.target == .sheet
    }

    var isBackgroundAndSheetSwipeEnabled: Bool {
        verticalSwipeBehavior?.target == .backgroundAndSheet
    }
}

// MARK: - Nested types

public extension FloatingSheetConfiguration {
    enum BackgroundInteractionBehavior {
        case tapToDismiss
        case passTouchesThrough
        case consumeTouches
    }

    struct VerticalSwipeBehavior {
        public enum Target {
            /// Does not have any effect when ``FloatingSheetConfiguration/backgroundInteractionBehavior`` is set
            /// to ``BackgroundInteractionBehavior/passTouchesThrough``.
            case background

            case sheet

            /// Background swipes will have no effect when ``FloatingSheetConfiguration/backgroundInteractionBehavior`` is set
            /// to ``BackgroundInteractionBehavior/passTouchesThrough``.
            case backgroundAndSheet
        }

        var target: Target
        var threshold: CGFloat

        public init(target: Target = .backgroundAndSheet, threshold: CGFloat = 100) {
            self.target = target
            self.threshold = threshold
        }
    }
}

// MARK: - SwiftUI.EnvironmentValues entry

extension EnvironmentValues {
    @Entry var floatingSheetConfiguration = FloatingSheetConfiguration(
        minHeightFraction: 0.3,
        maxHeightFraction: 0.8,
        sheetBackgroundColor: Color(.systemBackground),
        backgroundInteractionBehavior: FloatingSheetConfiguration.BackgroundInteractionBehavior.tapToDismiss,
        verticalSwipeBehavior: FloatingSheetConfiguration.VerticalSwipeBehavior(),
        keyboardHandlingEnabled: true
    )
}
