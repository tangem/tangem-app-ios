//
//  PopoverModifier.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

/// The `PopoverModifier` which will be able to show a bubble with some text
@available(iOS 16.4, *)
public struct PopoverModifier: ViewModifier {
    private let text: TextType
    @Binding private var isPresented: Bool

    /// Strange hack but it's important for a multiline text. More then 3 lines
    @State private var textSize: CGSize = .zero

    public init(text: TextType, isPresented: Binding<Bool>) {
        self.text = text
        _isPresented = isPresented
    }

    public func body(content: Content) -> some View {
        content
            .popover(isPresented: $isPresented, content: {
                textView
                    .lineLimit(nil)
                    .readGeometry(\.frame.size, bindTo: $textSize)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: textSize.height)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .onTapGesture { isPresented = false }
                    .presentationCompactAdaptation(.popover)
                    .presentationBackgroundInteraction(.automatic)
                    .presentationCornerRadius(14)
                    .presentationBackground(Colors.Icon.secondary)
            })
    }

    @ViewBuilder
    private var textView: some View {
        switch text {
        case .rich(let text):
            Text(.init(text))
                .style(Fonts.Regular.footnote, color: Colors.Text.primary2)
        case .attributed(let text):
            Text(text)
        }
    }
}

@available(iOS 16.4, *)
public extension PopoverModifier {
    enum TextType {
        case rich(text: String)
        case attributed(text: AttributedString)
    }
}

public extension View {
    @available(iOS 16.4, *)
    func popover(_ text: String, isPresented: Binding<Bool>) -> some View {
        modifier(PopoverModifier(text: .rich(text: text), isPresented: isPresented))
    }

    @available(iOS 16.4, *)
    func popover(_ text: AttributedString, isPresented: Binding<Bool>) -> some View {
        modifier(PopoverModifier(text: .attributed(text: text), isPresented: isPresented))
    }

    @available(iOS 16.4, *)
    func popover(_ text: PopoverModifier.TextType, isPresented: Binding<Bool>) -> some View {
        modifier(PopoverModifier(text: text, isPresented: isPresented))
    }

    /// Backports ``View.popover(_:axes:)``.
    /// - Attention: No-op for iOS < 16.4.
    /// - Parameters:
    ///   - text: The text which will be presented in the popover bubble
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the popover content that you return from the modifier's
    ///     `content` closure.
    ///
    /// - Returns: A view that's configured with the `PopoverModifier`
    @available(iOS, obsoleted: 16.4, message: "Use View.popover(_:isPresented:) instead.")
    @ViewBuilder
    func popoverBackport(_ text: String, isPresented: Binding<Bool>) -> some View {
        if #available(iOS 16.4, *) {
            modifier(PopoverModifier(text: .rich(text: text), isPresented: isPresented))
        } else {
            self
        }
    }
}
