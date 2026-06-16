//
//  TangemSearchField.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemUIUtils
import TangemAssets

public struct TangemSearchField: View, Setupable {
    public typealias Action = () -> Void
    public typealias BoolAction = (Bool) -> Void

    // MARK: - Dependencies

    @Binding private var text: String
    private let focusAction: Action?
    private let clearAction: Action?
    private let cancelAction: Action?
    private let onFocusChanged: BoolAction?

    // MARK: - State properties

    @FocusState private var isFocused: Bool
    @State private var showCancelButton: Bool = false

    // MARK: - Scaled properties

    @ScaledMetric private var horizontalSpacing: CGFloat = .unit(.x3)
    @ScaledMetric private var fieldHorizontalPadding: CGFloat = .unit(.x3)
    @ScaledMetric private var fieldCornerRadius: CGFloat = .unit(.x4)
    @ScaledMetric private var fieldSearchSpacing: CGFloat = .unit(.x1)
    @ScaledMetric private var fieldClearSpacing: CGFloat = .unit(.x1)
    @ScaledMetric private var searchIconSide: CGFloat = .unit(.x5)
    @ScaledMetric private var clearIconSide: CGFloat = .unit(.x6)

    // MARK: - Configuration

    private var fieldPlaceholderText: String = .empty
    private var fieldCornerStyle: CornerStyle = .capsule
    private var hasSearchIcon: Bool = true
    private var hasClearButton: Bool = true
    private var containerAccessibilityIdentifier: String?
    private var textFieldAccessibilityIdentifier: String?
    private var clearButtonAccessibilityIdentifier: String?

    private let animation: Animation = .easeInOut

    public init(
        text: Binding<String>,
        focusAction: Action? = nil,
        clearAction: Action? = nil,
        cancelAction: Action? = nil,
        onFocusChanged: BoolAction? = nil
    ) {
        _text = text
        self.focusAction = focusAction
        self.clearAction = clearAction
        self.cancelAction = cancelAction
        self.onFocusChanged = onFocusChanged
    }

    public var body: some View {
        HStack(spacing: horizontalSpacing) {
            field

            if showCancelButton {
                cancelButton
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(animation, value: focusTextState)
        .animation(animation, value: showCancelButton)
        .onChange(of: isFocused) {
            showCancelButton = $0
            onFocusChanged?($0)
        }
    }
}

// MARK: - Subviews

private extension TangemSearchField {
    var field: some View {
        fieldContent
            .padding(.horizontal, fieldHorizontalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Color.Tangem.Field.backgroundDefault, in: fieldShape)
            .contentShape(.rect)
            .onTapGesture(perform: onFieldTap)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(focusAction != nil ? .isButton : [])
            .accessibilityIdentifier(containerAccessibilityIdentifier)
    }

    var fieldContent: some View {
        HStack(spacing: fieldSearchSpacing) {
            if hasSearchIcon {
                searchIcon
            }

            ZStack(alignment: .leading) {
                if showPlaceholder {
                    textPlaceholder
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .identity
                        ))
                }

                HStack(spacing: fieldClearSpacing) {
                    textInput
                        .frame(width: inputWidth)

                    if hasClearButton, showClear {
                        clearButton
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .identity
                            ))
                    }
                }
            }
        }
    }

    var searchIcon: some View {
        Assets.DesignSystem.search.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiaryConstant)
            .frame(width: searchIconSide, height: searchIconSide)
    }

    var textInput: some View {
        TextField("", text: $text)
            .style(Font.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.primary)
            .focused($isFocused)
            .accessibilityIdentifier(textFieldAccessibilityIdentifier)
    }

    var textPlaceholder: some View {
        Text(fieldPlaceholderText)
            .style(Font.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.tertiary)
            .lineLimit(1)
    }

    var clearButton: some View {
        Assets.DesignSystem.clear.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiary)
            .frame(width: clearIconSide, height: clearIconSide)
            .contentShape(.rect)
            .onTapGesture(perform: onClear)
            .accessibilityAddTraits(clearAction != nil ? .isButton : [])
            .accessibilityIdentifier(clearButtonAccessibilityIdentifier)
    }

    var cancelButton: some View {
        TangemButton(
            content: .text(AttributedString(Localization.commonCancel)),
            action: onCancel
        )
        .setStyleType(.ghost)
        .setSize(.x9)
    }
}

// MARK: - Calculations

private extension TangemSearchField {
    var focusTextState: FocusTextState {
        if isFocused {
            return hasText ? .focusedText : .focusedEmpty
        } else {
            return hasText ? .unfocusedText : .unfocusedEmpty
        }
    }

    var showPlaceholder: Bool {
        [.focusedEmpty, .unfocusedEmpty].contains(focusTextState)
    }

    var showInput: Bool {
        [.focusedEmpty, .focusedText, .unfocusedText].contains(focusTextState)
    }

    var showClear: Bool {
        focusTextState == .focusedText
    }

    var hasText: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
    }

    var inputWidth: CGFloat? {
        showInput ? nil : 0
    }

    @ShapeBuilder
    var fieldShape: some Shape {
        switch fieldCornerStyle {
        case .rounded: .rect(cornerRadius: fieldCornerRadius)
        case .capsule: .capsule
        }
    }
}

// MARK: - Actions

private extension TangemSearchField {
    func onFieldTap() {
        if let focusAction {
            focusAction()
        } else {
            isFocused = true
        }
    }

    func onClear() {
        clearAction?()
    }

    func onCancel() {
        cancelAction?()
    }
}

// MARK: - States

private extension TangemSearchField {
    enum FocusTextState {
        case focusedText
        case focusedEmpty
        case unfocusedText
        case unfocusedEmpty
    }
}

// MARK: - Types

public extension TangemSearchField {
    enum CornerStyle {
        case rounded
        case capsule
    }
}

// MARK: - Setupable

public extension TangemSearchField {
    func placeholder(text: String) -> Self {
        map { $0.fieldPlaceholderText = text }
    }

    func cornerStyle(_ style: CornerStyle) -> Self {
        map { $0.fieldCornerStyle = style }
    }

    func configure(
        hasSearchIcon: Bool = true,
        hasClearButton: Bool = true
    ) -> Self {
        map {
            $0.hasSearchIcon = hasSearchIcon
            $0.hasClearButton = hasClearButton
        }
    }

    func containerAccessibilityIdentifier(_ identifier: String?) -> Self {
        map { $0.containerAccessibilityIdentifier = identifier }
    }

    func textFieldAccessibilityIdentifier(_ identifier: String?) -> Self {
        map { $0.textFieldAccessibilityIdentifier = identifier }
    }

    func clearButtonAccessibilityIdentifier(_ identifier: String?) -> Self {
        map { $0.clearButtonAccessibilityIdentifier = identifier }
    }
}
