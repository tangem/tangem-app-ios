//
//  FilterItem.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct FilterItem: View, Setupable {
    private let state: FilterItemState
    private let action: () -> Void

    private var explicitVariant: Variant?
    private var onClear: (() -> Void)?
    private var accessibilityLabel: String?
    private var clearAccessibilityLabel: String?

    @Environment(\.filterItemVariant) private var inheritedVariant

    @ScaledMetric private var height: CGFloat = Constants.height
    @ScaledMetric private var minWidth: CGFloat = Constants.minWidth
    @ScaledMetric private var iconSize: CGFloat = Constants.iconSize
    @ScaledMetric private var leadingInset: CGFloat = Constants.leadingInset
    @ScaledMetric private var trailingInset: CGFloat = Constants.trailingInset
    @ScaledMetric private var verticalInset: CGFloat = Constants.verticalInset
    @ScaledMetric private var iconSpacing: CGFloat = Constants.iconSpacing
    @ScaledMetric private var counterSpacing: CGFloat = Constants.counterSpacing

    public init(_ state: FilterItemState, action: @escaping () -> Void) {
        self.state = state
        self.action = action
    }

    @ViewBuilder
    public var body: some View {
        if case .loading = state {
            placeholder
        } else {
            chip
        }
    }

    private var placeholder: some View {
        Capsule()
            .fill(DesignSystem.Color.bgTransparentSecondary)
            .frame(width: Constants.shimmerWidth, height: height)
            .tangemShimmer()
            .environment(\.isShimmerActive, true)
    }

    private var chip: some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 0) {
                label

                trailingIcon
                    .padding(.leading, iconSpacing)
            }
            .padding(.leading, leadingInset)
            .padding(.trailing, trailingInset)
            .frame(minWidth: minWidth, minHeight: height)
            .clipShape(Capsule())
            .background(background)
            .contentShape(Capsule())
        }
        .buttonStyle(FilterItemPressStyle(pressColor: pressColor))
        .ifLet(accessibilityLabel) { $0.accessibilityLabel($1) }
        .overlay(alignment: .trailing) { clearHitTarget }
    }
}

// MARK: - Setupable

public extension FilterItem {
    func variant(_ variant: Variant) -> Self {
        map { $0.explicitVariant = variant }
    }

    func onClear(_ action: (() -> Void)?) -> Self {
        map { $0.onClear = action }
    }

    func accessibilityLabel(_ label: String?) -> Self {
        map { $0.accessibilityLabel = label }
    }

    func clearAccessibilityLabel(_ label: String?) -> Self {
        map { $0.clearAccessibilityLabel = label }
    }
}

// MARK: - Content

private extension FilterItem {
    var label: some View {
        HStack(spacing: 0) {
            Text(text)
                .style(DesignSystem.Font.subheadingMediumToken, color: textColor)
                .lineLimit(1)
                .contentTransition(.opacity)

            if let counter {
                Text("+\(counter)")
                    .style(DesignSystem.Font.subheadingMediumToken, color: counterColor)
                    .lineLimit(1)
                    .padding(.leading, counterSpacing)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, verticalInset)
    }

    var trailingIcon: some View {
        ZStack {
            icon(DesignSystem.Icons.ChevronDown.regular16)
                .opacity(isClearable ? 0 : 1)

            icon(DesignSystem.Icons.Cross.regular16)
                .opacity(isClearable ? 1 : 0)
        }
        .frame(width: iconSize, height: iconSize)
    }

    @ViewBuilder
    var clearHitTarget: some View {
        if isClearable, let onClear {
            SwiftUI.Button(action: onClear) {
                Color.clear
                    .frame(width: iconSize, height: iconSize)
                    .expandingHitArea(.all, by: Constants.clearHitAreaInset)
            }
            .buttonStyle(.plain)
            .padding(.trailing, trailingInset)
            .ifLet(clearAccessibilityLabel) { $0.accessibilityLabel($1) }
        }
    }

    func icon(_ image: ImageType) -> some View {
        image.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: iconSize, height: iconSize)
            .foregroundStyle(iconColor)
    }

    @ViewBuilder
    var background: some View {
        switch variant {
        case .material:
            Color.clear
                .tangemMaterialSurface(in: Capsule(), style: isActive ? .inverted : .default)
        case .transparent:
            Capsule()
                .fill(isActive ? DesignSystem.Color.bgInverse : DesignSystem.Color.bgTransparentSecondary)
        }
    }
}

// MARK: - State

private extension FilterItem {
    var variant: Variant {
        explicitVariant ?? inheritedVariant
    }

    var isActive: Bool {
        if case .active = state { return true }
        return false
    }

    var isClearable: Bool {
        isActive && onClear != nil
    }

    var text: String {
        switch state {
        case .inactive(let label): label
        case .active(let value, _): value
        case .loading: ""
        }
    }

    var counter: Int? {
        guard case .active(_, let counter) = state else { return nil }
        return counter
    }
}

// MARK: - Appearance

private extension FilterItem {
    var textColor: Color {
        isActive ? DesignSystem.Color.textInversePrimary : DesignSystem.Color.textSecondary
    }

    var counterColor: Color {
        isActive ? DesignSystem.Color.textInverseSecondary : DesignSystem.Color.textSecondary
    }

    var iconColor: Color {
        isActive ? DesignSystem.Color.iconInverse : DesignSystem.Color.iconSecondary
    }

    var pressColor: Color {
        isActive ? DesignSystem.Color.interactionPressInverse : DesignSystem.Color.interactionPressDefault
    }
}

// MARK: - Press state

private struct FilterItemPressStyle: ButtonStyle {
    let pressColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                Capsule()
                    .fill(pressColor)
                    .opacity(configuration.isPressed ? 1 : 0)
            }
            .animation(Constants.pressAnimation, value: configuration.isPressed)
    }
}

// MARK: - Constants

private enum Constants {
    static let height: CGFloat = 36
    static let minWidth: CGFloat = 64
    static let iconSize: CGFloat = 16
    static let leadingInset: CGFloat = 12
    static let trailingInset: CGFloat = 10
    static let verticalInset: CGFloat = 8
    static let iconSpacing: CGFloat = 6
    static let counterSpacing: CGFloat = 4
    static let shimmerWidth: CGFloat = 80
    static let clearHitAreaInset: CGFloat = 4

    static let pressAnimation: Animation = .timingCurve(0.8, 0, 0.6, 1, duration: 0.2)
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isActive = true

    VStack(alignment: .leading, spacing: 20) {
        ForEach(FilterItem.Variant.allCases, id: \.self) { variant in
            VStack(alignment: .leading, spacing: 8) {
                Text(String(describing: variant))
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)

                HStack(spacing: 4) {
                    FilterItem(.inactive(label: "Label")) {}
                    FilterItem(.active(value: "Value")) {}
                        .onClear {}
                    FilterItem(.active(value: "Value", counter: 1)) {}
                        .onClear {}
                    FilterItem(.loading) {}
                }
                .environment(\.filterItemVariant, variant)
            }
        }

        FilterItem(isActive ? .active(value: "Ethereum") : .inactive(label: "Network")) {
            isActive = true
        }
        .onClear { isActive = false }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(DesignSystem.Color.bgPrimary)
}
