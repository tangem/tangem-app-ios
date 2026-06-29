//
//  View+TangemSearchable.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Native `.searchable` on iOS 26+, custom `TangemSearch` capsule below.
    ///
    /// - Important: apply once at the container root (not inside an app-state `switch`) — avoids
    ///   the iOS 26 "search text field was already borrowed" crash. `prompt` must be unique per
    ///   screen: it's the iOS 26 UI-test locator. `accessibilityIdentifier` and `interactiveGlass`
    ///   affect the <26 capsule only — native `.searchable` exposes no hook for either, so iOS 26
    ///   tests must locate the field via `prompt`. `.bottom` placement has no native equivalent,
    ///   so on iOS 26 it falls back to `.automatic` — only the <26 capsule actually pins to the bottom.
    func tangemSearchable(
        text: Binding<String>,
        isActive: Binding<Bool>? = nil,
        prompt: String,
        accessibilityIdentifier: String? = nil,
        placement: TangemSearch.Placement = .automatic,
        interactiveGlass: Bool = true
    ) -> some View {
        modifier(
            TangemSearchableModifier(
                text: text,
                isActive: isActive,
                prompt: prompt,
                accessibilityIdentifier: accessibilityIdentifier,
                placement: placement,
                interactiveGlass: interactiveGlass
            )
        )
    }
}

private struct TangemSearchableModifier: ViewModifier {
    @Binding var text: String
    let isActive: Binding<Bool>?
    let prompt: String
    let accessibilityIdentifier: String?
    let placement: TangemSearch.Placement
    let interactiveGlass: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            nativeSearchable(content)
        } else {
            customSearchable(content)
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func nativeSearchable(_ content: Content) -> some View {
        if let isActive {
            content.searchable(
                text: $text,
                isPresented: isActive,
                placement: nativePlacement,
                prompt: prompt
            )
        } else {
            content.searchable(
                text: $text,
                placement: nativePlacement,
                prompt: prompt
            )
        }
    }

    private func customSearchable(_ content: Content) -> some View {
        content.safeAreaInset(edge: customEdge) {
            TangemSearch(text: $text, isActive: isActive)
                .placeholder(prompt)
                .interactiveGlass(interactiveGlass)
                .textFieldAccessibilityIdentifier(accessibilityIdentifier)
                .padding(.horizontal, .unit(.x4))
                .padding(.vertical, .unit(.x2))
        }
    }

    @available(iOS 26.0, *)
    private var nativePlacement: SearchFieldPlacement {
        switch placement {
        case .top: .navigationBarDrawer(displayMode: .always)
        case .bottom, .automatic: .automatic
        }
    }

    private var customEdge: VerticalEdge {
        switch placement {
        case .bottom: .bottom
        case .top, .automatic: .top
        }
    }
}
