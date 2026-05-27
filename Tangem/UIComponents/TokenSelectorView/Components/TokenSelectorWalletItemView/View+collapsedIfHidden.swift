//
//  View+collapsedIfHidden.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    /// Keeps the view alive in the hierarchy but collapses it to zero height when hidden.
    /// This preserves SwiftUI view identity and prevents blink on show/hide transitions.
    func collapsedIfHidden(_ isHidden: Bool) -> some View {
        modifier(CollapsedIfHiddenViewModifier(isHidden: isHidden))
    }
}

private struct CollapsedIfHiddenViewModifier: ViewModifier {
    let isHidden: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isHidden ? 0 : 1)
            .frame(height: isHidden ? 0 : nil)
            .clipped()
            .allowsHitTesting(!isHidden)
            .animation(nil, value: isHidden)
    }
}
