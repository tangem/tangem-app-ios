//
//  View+KeyboardFocus.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Focusing while the push transition is still running makes UIKit fold the keyboard into that transition, so it
    /// slides in from the side. The delay lets the transition finish, and the keyboard rises from the bottom as usual.
    func focusOnAppear(
        _ isFocused: FocusState<Bool>.Binding,
        onlyOnce: Bool = false,
        delay: Duration = .milliseconds(500)
    ) -> some View {
        modifier(FocusOnAppearModifier(isFocused: isFocused, onlyOnce: onlyOnce, delay: delay))
    }
}

private struct FocusOnAppearModifier: ViewModifier {
    let isFocused: FocusState<Bool>.Binding
    let onlyOnce: Bool
    let delay: Duration

    @State private var hasFocused = false

    func body(content: Content) -> some View {
        content.task {
            do {
                try await Task.sleep(for: delay)

                let shouldSkipFocused = onlyOnce && hasFocused
                if !shouldSkipFocused {
                    isFocused.wrappedValue = true
                    hasFocused = true
                }
            } catch {
                // Task was cancelled
            }
        }
    }
}
