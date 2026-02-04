//
//  KeyboardToolbarViewModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public extension View {
    func keyboardToolbar<ToolbarContent: View>(@ViewBuilder toolbarContent: () -> ToolbarContent) -> some View {
        modifier(KeyboardToolbarViewModifier(toolbarContent: toolbarContent()))
    }

    func keyboardToolbar<ToolbarContent: View>(_ toolbarContent: ToolbarContent) -> some View {
        modifier(KeyboardToolbarViewModifier(toolbarContent: toolbarContent))
    }
}

struct KeyboardToolbarViewModifier<ToolbarContent: View>: ViewModifier {
    let toolbarContent: ToolbarContent

    @State private var keyboardHeight = CGFloat.zero

    func body(content: Content) -> some View {
        content
            .overlay {
                overlayToolbarContent
                    .background(toolbarBackground)
                    .padding(.bottom, keyboardHeight)
                    .opacity(toolbarOpacity)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(.all)
            }
            .animation(.keyboard, value: keyboardHeight)
            .keyboardHeight(bindTo: $keyboardHeight)
    }

    @ViewBuilder
    private var overlayToolbarContent: some View {
        if #available(iOS 26.0, *) {
            glassToolbar
        } else {
            regularToolbar
        }
    }

    @available(iOS 26.0, *)
    private var glassToolbar: some View {
        GlassEffectContainer(spacing: .zero) {
            toolbarContent
        }
        .padding(.bottom, 8)
    }

    private var regularToolbar: some View {
        VStack(spacing: .zero) {
            Divider()
                .frame(height: 1)
                .overlay(Colors.Stroke.primary)

            toolbarContent
        }
    }

    @ViewBuilder
    private var toolbarBackground: some View {
        if #unavailable(iOS 26.0) {
            Colors.Background.primary
        }
    }

    private var toolbarOpacity: CGFloat {
        let keyboardIsVisible = keyboardHeight > 0
        return keyboardIsVisible ? 1 : 0
    }
}
