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
    @State private var size: TangemBadgeV2Size = .x6
    @State private var variant: TangemBadgeV2Variant = .tinted
    @State private var appearance: TangemBadgeV2Appearance = .neutral
    @State private var slotStartMode: SlotMode = .off
    @State private var slotEndMode: SlotMode = .off
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
                Text("x9").tag(TangemBadgeV2Size.x9)
                Text("x6").tag(TangemBadgeV2Size.x6)
                Text("x4").tag(TangemBadgeV2Size.x4)
            }
            .pickerStyle(.segmented)

            Picker("Variant", selection: $variant) {
                Text("tinted").tag(TangemBadgeV2Variant.tinted)
                Text("solid").tag(TangemBadgeV2Variant.solid)
                Text("outline").tag(TangemBadgeV2Variant.outline)
            }
            .pickerStyle(.segmented)

            Picker("Appearance", selection: $appearance) {
                Text("neutral").tag(TangemBadgeV2Appearance.neutral)
                Text("info").tag(TangemBadgeV2Appearance.info)
                Text("error").tag(TangemBadgeV2Appearance.error)
                Text("warning").tag(TangemBadgeV2Appearance.warning)
                Text("success").tag(TangemBadgeV2Appearance.success)
            }
            .pickerStyle(.segmented)

            slotPicker("Slot Start", selection: $slotStartMode)
            slotPicker("Slot End", selection: $slotEndMode)

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
        configuredBadge
            // `@ScaledMetric` instances inside the badge are reconstructed on `.size(_:)` —
            // forcing a fresh view identity per size keeps the live ScaledMetric values
            // in sync with the picked size as Dynamic Type changes.
            .id(size)
            .dynamicTypeSize(dynamicTypeSize)
    }

    @ViewBuilder
    private var configuredBadge: some View {
        let base = TangemBadgeV2(label: customText, accessibilityLabel: nil)
            .size(size)
            .variant(variant)
            .appearance(appearance)

        switch (slotStartMode, slotEndMode) {
        case (.off, .off): base
        case (.icon, .off): base.slotStart(size.slotIcon)
        case (.custom, .off): base.slotStart { customSlotContent }
        case (.off, .icon): base.slotEnd(size.slotIcon)
        case (.icon, .icon): base.slotStart(size.slotIcon).slotEnd(size.slotIcon)
        case (.custom, .icon): base.slotStart { customSlotContent }.slotEnd(size.slotIcon)
        case (.off, .custom): base.slotEnd { customSlotContent }
        case (.icon, .custom): base.slotStart(size.slotIcon).slotEnd { customSlotContent }
        case (.custom, .custom): base.slotStart { customSlotContent }.slotEnd { customSlotContent }
        }
    }

    /// Demonstrates that arbitrary `View` content fits into a slot — not just
    /// `ImageType` icons. A plain `Circle` shows the badge stamps its scaled
    /// frame on slot content so Dynamic Type stays consistent.
    private var customSlotContent: some View {
        Circle()
            .fill(DesignSystem.Color.iconBrand)
            .aspectRatio(1, contentMode: .fit)
    }

    private func slotPicker(_ title: String, selection: Binding<SlotMode>) -> some View {
        HStack(spacing: 8) {
            Text(title).font(.caption)
            Picker(title, selection: selection) {
                Text("off").tag(SlotMode.off)
                Text("icon").tag(SlotMode.icon)
                Text("custom").tag(SlotMode.custom)
            }
            .pickerStyle(.segmented)
        }
    }

    enum SlotMode: Hashable {
        case off
        case icon
        case custom
    }
}

// MARK: - Previews

#if DEBUG

private struct BadgeMatrixView: View {
    let variants: [TangemBadgeV2Variant] = [.tinted, .solid, .outline]
    let appearances: [TangemBadgeV2Appearance] = [.neutral, .info, .error, .warning, .success]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(variants, id: \.self) { variant in
                VStack(alignment: .leading, spacing: 8) {
                    Text(variantName(variant))
                        .font(.headline)

                    HStack(spacing: 8) {
                        ForEach(appearances, id: \.self) { appearance in
                            TangemBadgeV2(label: appearanceName(appearance), accessibilityLabel: nil)
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

    private func variantName(_ variant: TangemBadgeV2Variant) -> String {
        switch variant {
        case .tinted: "Tinted"
        case .solid: "Solid"
        case .outline: "Outline"
        }
    }

    private func appearanceName(_ appearance: TangemBadgeV2Appearance) -> String {
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
    let sizes: [TangemBadgeV2Size] = [.x9, .x6, .x4]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sizes, id: \.self) { size in
                HStack(spacing: 12) {
                    Text(sizeName(size))
                        .frame(width: 40, alignment: .leading)

                    TangemBadgeV2(label: "Label", accessibilityLabel: nil)
                        .size(size)

                    TangemBadgeV2(label: "Label", accessibilityLabel: nil)
                        .size(size)
                        .slotStart(size.slotIcon)

                    TangemBadgeV2(label: "Label", accessibilityLabel: nil)
                        .size(size)
                        .slotStart(size.slotIcon)
                        .slotEnd(size.slotIcon)

                    TangemBadgeV2(label: "Label", accessibilityLabel: nil)
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

    private func sizeName(_ size: TangemBadgeV2Size) -> String {
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

private extension TangemBadgeV2Size {
    var slotIcon: ImageType {
        switch self {
        case .x9: DesignSystem.Icons.SignUsd.regular20
        case .x6: DesignSystem.Icons.SignUsd.regular16
        case .x4: DesignSystem.Icons.SignUsd.regular12
        }
    }
}
