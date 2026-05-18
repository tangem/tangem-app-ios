//
//  TangemButtonV2Previews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase helpers

private let showcaseStyleTypes: [TangemButtonV2.StyleType] = [
    .brand,
    .default,
    .secondary,
    .material(.glass),
    .outline,
    .ghost,
    .inverse,
    .positive,
]

private func styleTypeLabel(_ style: TangemButtonV2.StyleType) -> String {
    switch style {
    case .brand: "brand"
    case .default: "default"
    case .secondary: "secondary"
    case .material: "material"
    case .outline: "outline"
    case .ghost: "ghost"
    case .inverse: "inverse"
    case .positive: "positive"
    }
}

// MARK: - Showcase

public struct TangemButtonV2Showcase: View {
    @State private var styleType: TangemButtonV2.StyleType = .material(.glass)
    @State private var size: TangemButtonV2.Size = .x12
    @State private var isEnabled: Bool = true
    @State private var isLoading: Bool = false
    @State private var horizontalLayout: TangemButtonV2.HorizontalLayout = .intrinsic
    @State private var contentKind: ContentKind = .label
    @State private var iconStartEnabled = false
    @State private var iconEndEnabled = false
    @State private var customText: String = "Button"
    @State private var dynamicTypeIndex: Int = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0
    @State private var tapCount = 0

    private enum ContentKind: String, CaseIterable {
        case label
        case longLabel
        case iconOnly
    }

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                menuPickerRow(
                    title: "style",
                    cases: showcaseStyleTypes,
                    binding: stylePickerBinding,
                    label: styleTypeLabel
                )
                pickerRow(
                    title: "size",
                    cases: TangemButtonV2.Size.allCases,
                    binding: $size,
                    label: { String(describing: $0) }
                )
                Toggle("isEnabled", isOn: $isEnabled)
                Toggle("isLoading", isOn: $isLoading)
                pickerRow(
                    title: "layout",
                    cases: TangemButtonV2.HorizontalLayout.allCases,
                    binding: $horizontalLayout,
                    label: { String(describing: $0) }
                )
                pickerRow(
                    title: "content",
                    cases: ContentKind.allCases,
                    binding: $contentKind,
                    label: { $0.rawValue }
                )

                HStack(spacing: 8) {
                    Text("custom text:").font(.caption)
                    TextField("Enter button text", text: $customText)
                        .textFieldStyle(.roundedBorder)
                }

                Stepper(
                    "DT: \(String(describing: dynamicTypeSize))",
                    value: $dynamicTypeIndex,
                    in: 0 ... (Self.dynamicTypeAllCases.count - 1)
                )

                if case .material = styleType {
                    pickerRow(
                        title: "material",
                        cases: TangemButtonV2.Material.allCases,
                        binding: materialPickerBinding,
                        label: { String(describing: $0) }
                    )
                }

                if contentKind != .iconOnly {
                    Toggle("icon start", isOn: $iconStartEnabled)
                    Toggle("icon end", isOn: $iconEndEnabled)
                }

                Divider()

                Text("taps: \(tapCount)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                preview
                    // Force a fresh mount whenever the size changes. The system's Glass
                    // press-indicator caches its geometry on first mount and doesn't recompute
                    // when @ScaledMetric values inside `Style` change due to a size switch —
                    // leaving a stale press-shape inside the new outer capsule. Showcase-only
                    // concern: production never resizes a live button.
                    .id(size)
                    .dynamicTypeSize(dynamicTypeSize)
                    .padding(.vertical, 32)
                    // Colorful backdrop so blur (`.regularMaterial`) and solid (no backdrop)
                    // are visually distinct — on a flat background they both collapse to
                    // ~white capsules and become indistinguishable.
                    .frame(maxWidth: .infinity)
                    .background(materialBackdrop)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var preview: some View {
        let action: () -> Void = { tapCount += 1 }
        let iconStart: ImageType? = iconStartEnabled ? DesignSystem.Icons.ArrowUp.regular20 : nil
        let iconEnd: ImageType? = iconEndEnabled ? DesignSystem.Icons.ArrowDown.regular20 : nil
        let button: TangemButtonV2 = {
            switch contentKind {
            case .label:
                return TangemButtonV2(
                    label: AttributedString(customText),
                    iconStart: iconStart,
                    iconEnd: iconEnd,
                    accessibilityLabel: nil,
                    action: action
                )
            case .longLabel:
                return TangemButtonV2(
                    label: AttributedString("This is a very long button label that may wrap or truncate"),
                    iconStart: iconStart,
                    iconEnd: iconEnd,
                    accessibilityLabel: nil,
                    action: action
                )
            case .iconOnly:
                return TangemButtonV2(
                    icon: DesignSystem.Icons.ArrowDown.regular24,
                    accessibilityLabel: "Arrow down",
                    action: action
                )
            }
        }()

        button
            .size(size)
            .styleType(styleType)
            .horizontalLayout(horizontalLayout)
            .isLoading(isLoading)
            .disabled(!isEnabled)
    }

    /// Picker binding that normalises `.material(_)` to its canonical `showcaseStyleTypes`
    /// representative so the picker's hash-based selection match never drifts when the
    /// material sub-picker flips the associated tier.
    private var stylePickerBinding: Binding<TangemButtonV2.StyleType> {
        Binding(
            get: {
                if case .material = styleType { return .material(.glass) }
                return styleType
            },
            set: { newValue in
                // Tapping the "material" segment shouldn't reset the previously chosen tier.
                if case .material = newValue, case .material(let current) = styleType {
                    styleType = .material(current)
                } else {
                    styleType = newValue
                }
            }
        )
    }

    /// Read/write Material binding extracted from the `.material(_)` case. Defaults to
    /// `.glass` when the current variant is not material (the picker is hidden in that case
    /// anyway).
    private var materialPickerBinding: Binding<TangemButtonV2.Material> {
        Binding(
            get: {
                if case .material(let m) = styleType { return m }
                return .glass
            },
            set: { newValue in styleType = .material(newValue) }
        )
    }

    private var materialBackdrop: some View {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.5, blue: 0.95),
                Color(red: 0.85, green: 0.3, blue: 0.6),
                Color(red: 0.95, green: 0.7, blue: 0.2),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func pickerRow<Value: Hashable>(
        title: String,
        cases: [Value],
        binding: Binding<Value>,
        label: @escaping (Value) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption)
            Picker(title, selection: binding) {
                ForEach(cases, id: \.self) { value in
                    Text(label(value)).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    /// Dropdown variant — used when the option set is too long for a segmented row.
    private func menuPickerRow<Value: Hashable>(
        title: String,
        cases: [Value],
        binding: Binding<Value>,
        label: @escaping (Value) -> String
    ) -> some View {
        HStack {
            Text(title).font(.caption)
            Spacer()
            Picker(title, selection: binding) {
                ForEach(cases, id: \.self) { value in
                    Text(label(value)).tag(value)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Showcase") {
    TangemButtonV2Showcase()
}

#Preview("All sizes — brand") {
    VStack(spacing: 12) {
        ForEach(TangemButtonV2.Size.allCases, id: \.self) { size in
            TangemButtonV2(label: AttributedString("Button"), accessibilityLabel: nil, action: {})
                .size(size)
                .styleType(.brand)
        }
    }
    .padding()
}

#Preview("All variants — x10") {
    VStack(spacing: 12) {
        ForEach(showcaseStyleTypes, id: \.self) { style in
            TangemButtonV2(
                label: AttributedString(styleTypeLabel(style)),
                accessibilityLabel: nil,
                action: {}
            )
            .size(.x10)
            .styleType(style)
        }
    }
    .padding()
}

#Preview("Icon-only — all sizes") {
    HStack(spacing: 12) {
        ForEach(TangemButtonV2.Size.allCases, id: \.self) { size in
            TangemButtonV2(
                icon: DesignSystem.Icons.ArrowDown.regular24,
                accessibilityLabel: "Arrow down",
                action: {}
            )
            .size(size)
            .styleType(.brand)
        }
    }
    .padding()
}

#Preview("States — x12 brand") {
    VStack(spacing: 12) {
        TangemButtonV2(label: AttributedString("Normal"), accessibilityLabel: nil, action: {})
            .size(.x12)
            .styleType(.brand)

        TangemButtonV2(label: AttributedString("Disabled"), accessibilityLabel: nil, action: {})
            .size(.x12)
            .styleType(.brand)
            .disabled(true)

        TangemButtonV2(label: AttributedString("Loading"), accessibilityLabel: nil, action: {})
            .size(.x12)
            .styleType(.brand)
            .isLoading(true)
    }
    .padding()
}

#Preview("Material variant — glass vs blur") {
    VStack(spacing: 16) {
        ForEach(TangemButtonV2.Material.allCases, id: \.self) { tier in
            VStack(spacing: 8) {
                Text(String(describing: tier)).font(.caption)
                TangemButtonV2(
                    label: AttributedString("Material \(String(describing: tier))"),
                    accessibilityLabel: nil,
                    action: {}
                )
                .size(.x10)
                .styleType(.material(tier))
            }
        }
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.5, blue: 0.95),
                Color(red: 0.85, green: 0.3, blue: 0.6),
                Color(red: 0.95, green: 0.7, blue: 0.2),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#endif // DEBUG
