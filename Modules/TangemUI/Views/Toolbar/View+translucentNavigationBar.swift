//
//  View+translucentNavigationBar.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Gives the navigation bar a translucent background on every supported OS version.
    ///
    /// From iOS 26 the native scroll edge effect draws the background. iOS 27 resolves its automatic style to the hard
    /// one, so the soft style is pinned explicitly; pre-26 versions get the blur overlay instead.
    @ViewBuilder
    func translucentNavigationBar() -> some View {
        if #available(iOS 26.0, *) {
            softTopScrollEdgeEffect()
        } else {
            backportTranslucentNavigationBar()
        }
    }

    @ViewBuilder
    func softTopScrollEdgeEffect() -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self
        }
    }
}
