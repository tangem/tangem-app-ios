//
//  FloatingSheetConfiguration.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct FloatingSheetConfiguration: Equatable {
    public var maxHeightFraction: CGFloat
    public var sheetFrameUpdateAnimation: Animation?
    public var sheetBackgroundColor: Color
    public var backgroundInteractionBehavior: BackgroundInteractionBehavior
    public var verticalSwipeBehavior: VerticalSwipeBehavior?
    public var keyboardHandlingEnabled: Bool

    static let `default` = FloatingSheetConfiguration(
        maxHeightFraction: 0.8,
        sheetFrameUpdateAnimation: nil,
        sheetBackgroundColor: Colors.Background.tertiary,
        backgroundInteractionBehavior: .consumeTouches,
        verticalSwipeBehavior: nil,
        keyboardHandlingEnabled: true
    )
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
    enum BackgroundInteractionBehavior: Equatable {
        case tapToDismiss
        case passTouchesThrough
        case consumeTouches
    }

    struct VerticalSwipeBehavior: Equatable {
        public enum Target: Equatable {
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

        public init(target: Target, threshold: CGFloat) {
            self.target = target
            self.threshold = threshold
        }
    }
}

// MARK: - SwiftUI.PreferenceKey

public struct FloatingSheetConfigurationPreferenceKey: PreferenceKey {
    public static let defaultValue = FloatingSheetConfiguration.default

    public static func reduce(value: inout FloatingSheetConfiguration, nextValue: () -> FloatingSheetConfiguration) {
        value = nextValue()
    }
}
