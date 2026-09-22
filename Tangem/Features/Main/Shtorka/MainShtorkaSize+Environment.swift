//
//  MainShtorkaSize+Environment.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension EnvironmentValues {
    /// Whether the sheet is low enough to show a screen's header alone. Follows the sheet's height through a
    /// drag, unlike the selected detent in `mainShtorkaSize`.
    @Entry var mainShtorkaContentIsCollapsed = false

    /// The size of the feed sheet a screen is pushed in, `nil` for a screen outside of it.
    @Entry var mainShtorkaSize: ShtorkaSize?
}

extension Optional where Wrapped == ShtorkaSize {
    var isFeedSheet: Bool {
        self != nil
    }

    var isCollapsedFeedSheet: Bool {
        self == .collapsed
    }

    var isNonFullFeedSheet: Bool {
        isFeedSheet && self != .full
    }
}

extension View {
    func hiddenWhileCollapsed() -> some View {
        modifier(MainShtorkaCollapsedContentModifier())
    }
}

private struct MainShtorkaCollapsedContentModifier: ViewModifier {
    @Environment(\.mainShtorkaContentIsCollapsed) private var isCollapsed

    func body(content: Content) -> some View {
        content
            .opacity(isCollapsed ? 0 : 1)
            .allowsHitTesting(!isCollapsed)
            .accessibilityHidden(isCollapsed)
    }
}
