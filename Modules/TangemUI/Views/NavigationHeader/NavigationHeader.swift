//
//  NavigationHeader.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import BlurSwiftUI
import TangemAssets
import TangemUIUtils

public struct NavigationHeader<L: View, P: View, T: View>: View {
    private let leadingContent: L
    private let principalContent: P
    private let trailingContent: T

    private var backgroundBottomInset: CGFloat = 0
    private var backgroundColor: Color?

    public init(
        @ViewBuilder leadingContent: () -> L,
        @ViewBuilder principalContent: () -> P,
        @ViewBuilder trailingContent: () -> T
    ) {
        self.leadingContent = leadingContent()
        self.principalContent = principalContent()
        self.trailingContent = trailingContent()
    }

    public var body: some View {
        HStack(spacing: 0) {
            leadingContent
            Spacer(minLength: 8)
            trailingContent
        }
        .overlay(alignment: .center) {
            principalContent
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(alignment: .top) {
            let coversContentBelow = backgroundBottomInset > 0
            let startingInset: VariableBlur.GradientSizing? = coversContentBelow ? .relative(fraction: NavigationHeaderConstants.extendedBlurStart) : nil

            VariableBlur(direction: .down)
                .maximumBlurRadius(coversContentBelow ? NavigationHeaderConstants.extendedBlurRadius : NavigationHeaderConstants.blurRadius)
                .blurStartingInset(startingInset)
                .dimmingTintColor(overriding: backgroundColor)
                .dimmingAlpha(.constant(alpha: 0.5))
                .dimmingOvershoot(nil)
                .dimmingStartingInset(startingInset)
                .ignoresSafeArea()
                .padding(.bottom, coversContentBelow ? -(backgroundBottomInset + NavigationHeaderConstants.extendedBlurOvershoot) : 0)
                .allowsHitTesting(false)
        }
    }
}

private extension VariableBlur {
    func dimmingTintColor(overriding color: Color?) -> VariableBlur {
        color.map { dimmingTintColor($0) } ?? self
    }
}

// MARK: - Setupable

extension NavigationHeader: Setupable {
    /// Extends the backdrop below the navigation controls, so content pinned under them is covered too.
    public func backgroundBottomInset(_ inset: CGFloat) -> Self {
        map { $0.backgroundBottomInset = inset }
    }

    public func backgroundColor(_ color: Color) -> Self {
        map { $0.backgroundColor = color }
    }
}

// MARK: - Constants

private enum NavigationHeaderConstants {
    static let blurRadius: CGFloat = 3.5
    static let extendedBlurRadius: CGFloat = 12
    static let extendedBlurStart: CGFloat = 0.75
    static let extendedBlurOvershoot: CGFloat = 24
}
