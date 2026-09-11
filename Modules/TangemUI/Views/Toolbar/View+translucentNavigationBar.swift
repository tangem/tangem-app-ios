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
    /// On iOS 26 the native scroll edge effect draws the background correctly. iOS 27 resolves the same effect's
    /// automatic style to a nearly opaque fill, so there it gives way to the blur overlay used on pre-26 versions.
    @ViewBuilder
    func translucentNavigationBar() -> some View {
        if #available(iOS 27.0, *) {
            scrollEdgeEffectHidden(true, for: .top)
                .backportTranslucentNavigationBar()
        } else if #available(iOS 26.0, *) {
            self
        } else {
            backportTranslucentNavigationBar()
        }
    }
}
