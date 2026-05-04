//
//  OnScreenVisibilityChangeViewModifier.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Convenience extensions

public extension View {
    /// Fires `action` whenever the view's on-screen visibility changes.
    /// Detection is based on `GeometryReader` frame intersection with the screen bounds.
    func onScreenVisibilityChange(_ action: @escaping (_ isVisible: Bool) -> Void) -> some View {
        modifier(OnScreenVisibilityChangeViewModifier(action: action))
    }
}

// MARK: - Private implementation

private struct OnScreenVisibilityChangeViewModifier: ViewModifier {
    let action: (_ isVisible: Bool) -> Void

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .readGeometry(\.frame, inCoordinateSpace: .global) { frame in
                let screenBounds = UIScreen.main.bounds
                let newIsVisible = frame.width > 0 && frame.height > 0 && screenBounds.intersects(frame)

                guard newIsVisible != isVisible else {
                    return
                }

                isVisible = newIsVisible
                action(newIsVisible)
            }
    }
}
