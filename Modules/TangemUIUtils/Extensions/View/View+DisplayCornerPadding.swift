//
//  View+DisplayCornerPadding.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// A stopgap for hand-made bars on full-screen views that the iPhone Duo pushes into the rounded corner:
    /// there the status bar moves to the side, so the top safe area inset is 0. The values are eyeballed,
    /// not taken from the system. Don't use it in new code — put the bar into `topNavigation`
    /// or a system toolbar, which keeps clear of the corners on its own.
    func displayCornerPadding() -> some View {
        modifier(DisplayCornerPaddingModifier())
    }
}

private struct DisplayCornerPaddingModifier: ViewModifier {
    @State private var insets = EdgeInsets()

    func body(content: Content) -> some View {
        content
            .padding(insets)
            .onGeometryChange(for: EdgeInsets.self, of: cornerInsets(in:)) { insets in
                self.insets = insets
            }
    }

    private func cornerInsets(in proxy: GeometryProxy) -> EdgeInsets {
        let topSafeAreaInset = proxy.safeAreaInsets.top

        guard proxy.frame(in: .global).minY < 1, topSafeAreaInset < Constants.top else {
            return EdgeInsets()
        }

        return EdgeInsets(
            top: Constants.top - topSafeAreaInset,
            leading: Constants.horizontal,
            bottom: .zero,
            trailing: Constants.horizontal
        )
    }
}

// MARK: - Constants

private extension DisplayCornerPaddingModifier {
    enum Constants {
        static let top: CGFloat = 26
        static let horizontal: CGFloat = 12
    }
}
