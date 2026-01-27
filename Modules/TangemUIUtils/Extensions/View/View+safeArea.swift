//
//  View+safeArea.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct BottomPaddingIfZeroSafeArea: ViewModifier {
    let padding: CGFloat

    private var bottomPadding: CGFloat {
        UIApplication.safeAreaInsets.bottom == .zero ? padding : 0
    }

    func body(content: Content) -> some View {
        content
            .padding(.bottom, bottomPadding)
    }
}

public extension View {
    /// Adds bottom padding only on devices that have zero bottom safe area (e.g. devices with a home button).
    /// 6 points by default
    func bottomPaddingIfZeroSafeArea(_ padding: CGFloat = 6) -> some View {
        modifier(BottomPaddingIfZeroSafeArea(padding: padding))
    }
}
