//
//  TangemSearch.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUIUtils

/// Prefer the `tangemSearchable(...)` modifier for screen-level
/// search — it routes to the native `.searchable` on iOS 26+ and to this capsule below,
/// keeping the OS fallback in one place. Use this View directly only for inline / bottom-sheet
/// search where `safeAreaInset`-pinned placement doesn't fit.
public struct TangemSearch: View, Setupable {
    // MARK: - Dependencies

    @Binding private var text: String
    private let isActive: Binding<Bool>?
    private let clearAction: (() -> Void)?
    private let cancelAction: (() -> Void)?
    private let onFocusChanged: ((Bool) -> Void)?

    // MARK: - State

    @FocusState private var isFocused: Bool
    @State private var showsClearButton: Bool = false
    @State private var showsCloseButtonState: Bool = false

    // MARK: - Scaled metrics

    @ScaledMetric private var searchIconSide: CGFloat = 20
    @ScaledMetric private var fieldHeight = Constants.closeButtonSize.height

    // MARK: - Configuration

    var placeholderText: String = .empty
    var showsCloseButton: Bool = true
    var interactiveGlass: Bool = true
    var containerAccessibilityIdentifier: String?
    var textFieldAccessibilityIdentifier: String?
    var clearButtonAccessibilityIdentifier: String?
    var closeButtonAccessibilityIdentifier: String?

    public init(
        text: Binding<String>,
        isActive: Binding<Bool>? = nil,
        clearAction: (() -> Void)? = nil,
        cancelAction: (() -> Void)? = nil,
        onFocusChanged: ((Bool) -> Void)? = nil
    ) {
        _text = text
        self.isActive = isActive
        self.clearAction = clearAction
        self.cancelAction = cancelAction
        self.onFocusChanged = onFocusChanged
    }

    public var body: some View {
        HStack(spacing: Constants.spacing) {
            field

            if showsCloseButton, showsCloseButtonState {
                closeButton
                    .transition(.opacity)
            }
        }
        // Lock the capsule and its placeholder/text into one geometry unit so they translate
        // together when a parent moves the field (e.g. a keyboard-driven `safeAreaInset`),
        // instead of each subview interpolating its position independently.
        .lockedGeometry()
        .onAppear(perform: syncInitialState)
        .onChange(of: isFocused) { newValue in
            syncButtons()
            isActive?.wrappedValue = newValue
            onFocusChanged?(newValue)
        }
        .onChange(of: text) { _ in
            syncButtons()
        }
        .onChange(of: isActive?.wrappedValue) { newValue in
            guard let newValue, newValue != isFocused else { return }
            isFocused = newValue
        }
    }
}

// MARK: - Geometry

private extension View {
    @ViewBuilder
    func lockedGeometry() -> some View {
        if #available(iOS 17.0, *) {
            geometryGroup()
        } else {
            self
        }
    }
}

// MARK: - Subviews

private extension TangemSearch {
    var field: some View {
        fieldContent
            .padding(.horizontal, Constants.fieldHorizontalPadding)
            .frame(height: fieldHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tangemMaterialSurface(in: Capsule(), interactive: interactiveGlass)
            .contentShape(Capsule())
            .onTapGesture(perform: onFieldTap)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(containerAccessibilityIdentifier)
    }

    var fieldContent: some View {
        HStack(spacing: Constants.spacing) {
            searchIcon

            ZStack(alignment: .leading) {
                if !hasText {
                    placeholder
                        .transition(.asymmetric(insertion: .opacity, removal: .identity))
                }

                textField
            }

            if showsClearButton {
                clearButton
                    .transition(.opacity)
            }
        }
    }

    var searchIcon: some View {
        DesignSystem.Icons.Search.regular20.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .frame(width: searchIconSide, height: searchIconSide)
            .accessibilityHidden(true)
    }

    var textField: some View {
        TextField("", text: $text)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .tint(DesignSystem.Color.iconBrand)
            .focused($isFocused)
            .accessibilityLabel(fieldAccessibilityLabel)
            .accessibilityIdentifier(textFieldAccessibilityIdentifier)
    }

    var placeholder: some View {
        Text(placeholderText)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
            .accessibilityHidden(true)
    }

    var clearButton: some View {
        TangemButtonV2(
            icon: DesignSystem.Icons.CrossCircle.filled20,
            accessibilityLabel: Localization.commonReset,
            action: onClear
        )
        .styleType(.ghost)
        .size(.x9)
        .accessibilityIdentifier(clearButtonAccessibilityIdentifier)
        .padding(Constants.clearButtonInset)
    }

    var closeButton: some View {
        TangemButtonV2(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonCancel,
            action: onClose
        )
        .styleType(.material(.glass))
        .size(Constants.closeButtonSize)
        .accessibilityIdentifier(closeButtonAccessibilityIdentifier)
    }
}

// MARK: - Calculations

private extension TangemSearch {
    var hasText: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
    }

    var fieldAccessibilityLabel: String {
        placeholderText.isEmpty ? Localization.commonSearch : placeholderText
    }

    func syncButtons() {
        let shouldShowClose = isFocused || hasText
        withAnimation(shouldShowClose ? Constants.openingAnimation : Constants.closingAnimation) {
            showsClearButton = hasText
            showsCloseButtonState = shouldShowClose
        }
    }

    func syncInitialState() {
        if let active = isActive?.wrappedValue {
            isFocused = active
        }
        showsClearButton = hasText
        showsCloseButtonState = isFocused || hasText
    }
}

// MARK: - Actions

private extension TangemSearch {
    func onFieldTap() {
        isFocused = true
    }

    func onClear() {
        text = .empty
        isFocused = true
        clearAction?()
    }

    func onClose() {
        text = .empty
        isFocused = false
        cancelAction?()
    }
}

// MARK: - Constants

private extension TangemSearch {
    enum Constants {
        static let spacing: CGFloat = 8
        static let fieldHorizontalPadding: CGFloat = 12
        static let clearButtonInset: CGFloat = -8
        static let closeButtonSize: TangemButtonV2.Size = .x11
        static let openingAnimation: Animation = .timingCurve(0.8, 0, 0.2, 1, duration: 0.3)
        static let closingAnimation: Animation = .timingCurve(0.8, 0, 0.8, 1, duration: 0.3)
    }
}
