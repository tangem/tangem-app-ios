//
//  TangemShimmerShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemShimmerShowcase: View {
    @State private var customWidth: CGFloat = 200
    @State private var customHeight: CGFloat = 40
    @State private var customCornerRadius: CGFloat = 0
    @State private var useCapsuleCorner: Bool = true
    @State private var modifierActive = true
    @State private var textAlignment: TangemShimmer.Alignment = .leading
    @State private var isRTL: Bool = false
    @State private var reduceMotion: Bool = false
    @State private var dynamicTypeIndex: Int = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                dynamicTypeSection
                defaultVariantSection
                textVariantSection
                customVariantSection
                modifierSection
                listExampleSection
                screenExampleSection
            }
            .padding(24)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .dynamicTypeSize(dynamicTypeSize)
        .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
        // SPI: the public `accessibilityReduceMotion` is get-only; its writable backing key lets the
        // showcase drive the real production branch. Showcase/DEBUG-only — never use in shipping logic.
        #if DEBUG
            .environment(\._accessibilityReduceMotion, reduceMotion)
        #endif // DEBUG
    }

    // MARK: - Sections

    private var dynamicTypeSection: some View {
        section(title: "Environment") {
            Stepper(
                "DT: \(String(describing: dynamicTypeSize))",
                value: $dynamicTypeIndex,
                in: 0 ... (Self.dynamicTypeAllCases.count - 1)
            )
            Toggle("Right-to-left layout", isOn: $isRTL)
            Toggle("Reduce Motion (freeze shine)", isOn: $reduceMotion)
            Text("Text and custom variants both scale with Dynamic Type.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var defaultVariantSection: some View {
        section(title: "Default (fills parent)") {
            TangemShimmer()
                .frame(height: 80)
        }
    }

    private var textVariantSection: some View {
        section(title: "Text variant — every style") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Alignment", selection: $textAlignment) {
                    Text("Leading").tag(TangemShimmer.Alignment.leading)
                    Text("Center").tag(TangemShimmer.Alignment.center)
                    Text("Trailing").tag(TangemShimmer.Alignment.trailing)
                }
                .pickerStyle(.segmented)

                ForEach(TangemShimmer.TextStyle.allCases, id: \.self) { style in
                    HStack(spacing: 12) {
                        Text(String(describing: style))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(width: 110, alignment: .leading)
                        TangemShimmer().variant(.text(style: style, alignment: textAlignment))
                    }
                }
            }
        }
    }

    private var customVariantSection: some View {
        section(title: "Custom variant") {
            VStack(alignment: .leading, spacing: 12) {
                Stepper("Width: \(Int(customWidth))", value: $customWidth, in: 40 ... 320, step: 20)
                Stepper("Height: \(Int(customHeight))", value: $customHeight, in: 12 ... 120, step: 4)
                Toggle("Capsule corner (height/2)", isOn: $useCapsuleCorner)
                if !useCapsuleCorner {
                    Stepper("Corner radius: \(Int(customCornerRadius))", value: $customCornerRadius, in: 0 ... 60, step: 2)
                }

                TangemShimmer()
                    .variant(.custom(
                        width: customWidth,
                        height: customHeight,
                        cornerRadius: useCapsuleCorner ? nil : customCornerRadius
                    ))
            }
        }
    }

    private var modifierSection: some View {
        section(title: ".tangemShimmer() modifier (env-driven)") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("isShimmerActive", isOn: $modifierActive)

                VStack(alignment: .leading, spacing: 6) {
                    Text("$69,786.00")
                        .font(.largeTitle.bold())
                    Text("Total amount")
                        .foregroundStyle(.secondary)
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                        .font(.body)
                }
                .tangemShimmer()
                .environment(\.isShimmerActive, modifierActive)
            }
        }
    }

    private var listExampleSection: some View {
        section(title: "List skeleton — text variants in a row") {
            VStack(spacing: 12) {
                ForEach(0 ..< 3) { _ in
                    HStack(spacing: 12) {
                        TangemShimmer()
                            .variant(.custom(width: 40, height: 40, cornerRadius: 20))
                        VStack(alignment: .leading, spacing: 6) {
                            TangemShimmer().variant(.text(style: .body))
                            TangemShimmer().variant(.text(style: .caption))
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Color.bgOpaquePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var screenExampleSection: some View {
        section(title: "Screen skeleton — composed primitives") {
            VStack(alignment: .leading, spacing: 16) {
                TangemShimmer().variant(.text(style: .display))
                TangemShimmer().variant(.text(style: .subheading))
                Spacer().frame(height: 8)
                TangemShimmer().variant(.custom(height: 120, cornerRadius: 16))
                HStack(spacing: 12) {
                    TangemShimmer().variant(.custom(height: 56, cornerRadius: 16))
                    TangemShimmer().variant(.custom(height: 56, cornerRadius: 16))
                }
            }
            .padding(16)
            .background(DesignSystem.Color.bgOpaquePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Helpers

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }
}
