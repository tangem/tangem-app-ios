//
//  TangemBadgeV2Previews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemBadgeV2Showcase: View {
    @State private var size: TangemBadgeV2.Size = .x6
    @State private var variant: TangemBadgeV2.Variant = .tinted
    @State private var appearance: TangemBadgeV2.Appearance = .neutral
    @State private var showSlotStart: Bool = false
    @State private var showSlotEnd: Bool = false
    @State private var customText: String = "Badge"
    @State private var dynamicTypeIndex: Int = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            pickerSection

            Spacer()

            badgePreview

            Spacer()
        }
        .padding()
    }

    private var pickerSection: some View {
        VStack(spacing: 8) {
            Picker("Size", selection: $size) {
                Text("x9").tag(TangemBadgeV2.Size.x9)
                Text("x6").tag(TangemBadgeV2.Size.x6)
                Text("x4").tag(TangemBadgeV2.Size.x4)
            }
            .pickerStyle(.segmented)

            Picker("Variant", selection: $variant) {
                Text("tinted").tag(TangemBadgeV2.Variant.tinted)
                Text("solid").tag(TangemBadgeV2.Variant.solid)
                Text("outline").tag(TangemBadgeV2.Variant.outline)
            }
            .pickerStyle(.segmented)

            Picker("Appearance", selection: $appearance) {
                Text("neutral").tag(TangemBadgeV2.Appearance.neutral)
                Text("info").tag(TangemBadgeV2.Appearance.info)
                Text("error").tag(TangemBadgeV2.Appearance.error)
                Text("warning").tag(TangemBadgeV2.Appearance.warning)
                Text("success").tag(TangemBadgeV2.Appearance.success)
            }
            .pickerStyle(.segmented)

            Toggle("Slot Start", isOn: $showSlotStart)
            Toggle("Slot End", isOn: $showSlotEnd)

            HStack {
                Text("label:").font(.caption)
                TextField("Enter badge label", text: $customText)
                    .textFieldStyle(.roundedBorder)
            }

            Stepper(
                "DT: \(String(describing: dynamicTypeSize))",
                value: $dynamicTypeIndex,
                in: 0 ... (Self.dynamicTypeAllCases.count - 1)
            )
        }
    }

    private var badgePreview: some View {
        TangemBadgeV2(label: customText, accessibilityLabel: nil)
            .size(size)
            .variant(variant)
            .appearance(appearance)
            .slotStart(showSlotStart ? size.slotIcon : nil)
            .slotEnd(showSlotEnd ? size.slotIcon : nil)
            // `@ScaledMetric` instances inside the badge are reconstructed on `.size(_:)` —
            // forcing a fresh view identity per size keeps the live ScaledMetric values
            // in sync with the picked size as Dynamic Type changes.
            .id(size)
            .dynamicTypeSize(dynamicTypeSize)
    }
}

// MARK: - Previews

#if DEBUG

private typealias _Badge = TangemBadgeV2

private struct BadgeMatrixView: View {
    let variants: [_Badge.Variant] = [.tinted, .solid, .outline]
    let appearances: [_Badge.Appearance] = [.neutral, .info, .error, .warning, .success]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(variants, id: \.self) { variant in
                VStack(alignment: .leading, spacing: 8) {
                    Text(variantName(variant))
                        .font(.headline)

                    HStack(spacing: 8) {
                        ForEach(appearances, id: \.self) { appearance in
                            _Badge(label: appearanceName(appearance), accessibilityLabel: nil)
                                .variant(variant)
                                .appearance(appearance)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.Tangem.Surface.level1)
    }

    private func variantName(_ variant: _Badge.Variant) -> String {
        switch variant {
        case .tinted: "Tinted"
        case .solid: "Solid"
        case .outline: "Outline"
        }
    }

    private func appearanceName(_ appearance: _Badge.Appearance) -> String {
        switch appearance {
        case .neutral: "Neutral"
        case .info: "Info"
        case .error: "Error"
        case .warning: "Warning"
        case .success: "Success"
        }
    }
}

private struct BadgeSizeComparisonView: View {
    let sizes: [_Badge.Size] = [.x9, .x6, .x4]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sizes, id: \.self) { size in
                HStack(spacing: 12) {
                    Text(sizeName(size))
                        .frame(width: 40, alignment: .leading)

                    _Badge(label: "Label", accessibilityLabel: nil)
                        .size(size)

                    _Badge(label: "Label", accessibilityLabel: nil)
                        .size(size)
                        .slotStart(size.slotIcon)

                    _Badge(label: "Label", accessibilityLabel: nil)
                        .size(size)
                        .slotStart(size.slotIcon)
                        .slotEnd(size.slotIcon)

                    _Badge(label: "Label", accessibilityLabel: nil)
                        .size(size)
                        .variant(.solid)
                        .appearance(.success)
                        .slotStart(size.slotIcon)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.Tangem.Surface.level1)
    }

    private func sizeName(_ size: _Badge.Size) -> String {
        switch size {
        case .x9: "x9"
        case .x6: "x6"
        case .x4: "x4"
        }
    }
}

#Preview("Interactive Demo") {
    TangemBadgeV2Showcase()
}

#Preview("Variant × Appearance Matrix") {
    BadgeMatrixView()
}

#Preview("Size Comparison") {
    BadgeSizeComparisonView()
}

#Preview("Dark Mode") {
    BadgeMatrixView()
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type — XXXLarge") {
    BadgeSizeComparisonView()
        .dynamicTypeSize(.xxxLarge)
}

#endif // DEBUG

// MARK: - Helpers

private extension TangemBadgeV2.Size {
    var slotIcon: ImageType {
        switch self {
        case .x9: DesignSystem.Icons.SignUsd.regular20
        case .x6: DesignSystem.Icons.SignUsd.regular16
        case .x4: DesignSystem.Icons.SignUsd.regular12
        }
    }
}
