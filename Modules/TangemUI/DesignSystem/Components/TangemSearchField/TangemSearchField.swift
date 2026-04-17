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
    // MARK: - State properties

    @Binding private var text: String
    @FocusState private var isFocused: Bool
    @State private var showCancelButton: Bool = false

    // MARK: - Scaled properties

    @ScaledMetric private var horizontalSpacing: CGFloat = .unit(.x3)
    @ScaledMetric private var fieldPadding: CGFloat = .unit(.x3)
    @ScaledMetric private var fieldCornerRadius: CGFloat = .unit(.x4)
    @ScaledMetric private var fieldSearchSpacing: CGFloat = .unit(.x1)
    @ScaledMetric private var fieldClearSpacing: CGFloat = .unit(.x1)
    @ScaledSize private var searchIconSize: CGSize = .init(bothDimensions: .unit(.x5))
    @ScaledSize private var clearIconSize: CGSize = .init(bothDimensions: .unit(.x6))

    // MARK: - Configuration

    private var fieldPlaceholderText: String = .empty
    private var fieldCornerStyle: CornerStyle = .capsule
    private var hasSearchIcon: Bool = true
    private var hasClearButton: Bool = true

    private let animation: Animation = .easeInOut

    public init(text: Binding<String>) {
        _text = text
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
        .onChange(of: isFocused) { showCancelButton = $0 }
    }
}

// MARK: - Subviews

private extension TangemSearchField {
    var field: some View {
        fieldContent
            .padding(fieldPadding)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color.Tangem.Field.backgroundDefault, in: fieldShape)
            .contentShape(.rect)
            .onTapGesture {
                isFocused = true
            }
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
            .frame(size: searchIconSize)
    }

    var textInput: some View {
        TextField("", text: $text)
            .style(.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.primary)
            .focused($isFocused)
    }

    var textPlaceholder: some View {
        Text(fieldPlaceholderText)
            .style(.Tangem.Body16.semibold, color: .Tangem.Text.Neutral.tertiary)
            .lineLimit(1)
    }

    var clearButton: some View {
        Assets.DesignSystem.clear.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiary)
            .frame(size: clearIconSize)
            .contentShape(.rect)
            .onTapGesture(perform: onClear)
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
    func onCancel() {
        clearSearch()
        lostFocus()
    }

    func onClear() {
        clearSearch()
    }

    func clearSearch() {
        text = .empty
    }

    func lostFocus() {
        isFocused = false
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
}
