//
//  View+backportTranslucentNavigationBar.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import BlurSwiftUI

public extension View {
    /// Applies a custom blur overlay that mimics the translucent navigation bar appearance introduced in iOS 26.
    ///
    /// The modifier hides the default navigation bar background and renders
    /// a variable blur aligned to the top safe area, creating a glass-like
    /// toolbar effect similar to the native iOS 26 navigation bar material.
    ///
    /// - Note: This is a visual approximation and does not fully replicate the native system effect or its animations.
    func backportTranslucentNavigationBar() -> some View {
        modifier(BackportTranslucentNavigationBar())
    }
}

struct BackportTranslucentNavigationBar: ViewModifier {
    @State private var safeAreaInsetTop = CGFloat.zero

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.top) { safeAreaInsetTop in
                self.safeAreaInsetTop = safeAreaInsetTop
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .overlay(alignment: .top) {
                BlurSwiftUI.VariableBlur(direction: .down)
                    .dimmingAlpha(.constant(alpha: 0.5))
                    .dimmingOvershoot(nil)
                    .frame(height: safeAreaInsetTop)
                    .ignoresSafeArea(edges: .top)

                Spacer()
            }
    }
}
