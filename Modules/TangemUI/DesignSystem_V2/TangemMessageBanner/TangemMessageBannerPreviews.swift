//
//  TangemMessageBannerPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemMessageBannerShowcase: View {
    private enum PreviewBackground: String, CaseIterable {
        case primary
        case secondary
        case inverse

        var color: Color {
            switch self {
            case .primary: DesignSystem.Color.bgPrimary
            case .secondary: DesignSystem.Color.bgSecondary
            case .inverse: DesignSystem.Color.bgInverse
            }
        }
    }

    @State private var variant: TangemMessageBannerVariant = .default
    @State private var contentAlign: TangemMessageBannerContentAlign = .start
    @State private var background: PreviewBackground = .primary
    @State private var hasGlowRing = true
    @State private var hasDescription = true
    @State private var hasSecondaryButton = true
    @State private var hasPrimaryButton = true
    @State private var hasCloseButton = false
    @State private var hasSlotStart = false
    @State private var hasSlotEnd = false
    @State private var hasExtraContent = false
    @State private var customText = false
    @State private var titleLineLimit = 3
    @State private var descriptionLineLimit = 3
    @State private var titleInput = "Would you predict?"
    @State private var descriptionInput = "France will win FIFA 2026"
    @State private var darkMode = false
    @State private var focused = false
    @State private var typeSize: DynamicTypeSize = .large
    @FocusState private var bannerFocused: Bool

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            previewArea

            ScrollView {
                controls.padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Preview (pinned)

    private var previewArea: some View {
        focusableBanner
            .dynamicTypeSize(typeSize)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(background.color)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .environment(\.colorScheme, darkMode ? .dark : .light)
            .padding(.horizontal)
    }

    @ViewBuilder
    private var focusableBanner: some View {
        if #available(iOS 17.0, *) {
            previewBanner
                .focusable()
                .focused($bannerFocused)
                .focusEffectDisabled()
                .onChange(of: focused) { _, newValue in bannerFocused = newValue }
                .onChange(of: bannerFocused) { _, newValue in focused = newValue }
        } else {
            previewBanner
        }
    }

    private var previewBanner: some View {
        baseBanner
            .slotStart {
                if hasSlotStart { leadingIcon }
            }
            .slotEnd {
                if hasCloseButton {
                    TangemMessageBannerCloseButton(accessibilityLabel: "Dismiss") {}
                } else if hasSlotEnd {
                    circlePlaceholder
                }
            }
            .extraBottom {
                if hasExtraContent { protectedByRow }
            }
            .variant(variant)
            .contentAlign(contentAlign)
            .showGlowRing(hasGlowRing)
            .titleLineLimit(titleLineLimit)
            .descriptionLineLimit(descriptionLineLimit)
            .secondaryButton(hasSecondaryButton ? .init(title: "Yes", action: {}) : nil)
            .primaryButton(hasPrimaryButton ? .init(title: "Oh, yes", action: {}) : nil)
    }

    private var baseBanner: TangemMessageBanner<EmptyView, EmptyView, EmptyView> {
        let description = hasDescription ? descriptionInput : nil

        if customText {
            return TangemMessageBanner(title: customTitle, description: description.map { AttributedString($0) })
        }

        return TangemMessageBanner(title: titleInput, description: description)
    }

    private var customTitle: AttributedString {
        var title = AttributedString(titleInput)
        title.foregroundColor = DesignSystem.Color.textStatusSuccess
        title.underlineStyle = .single
        return title
    }

    // MARK: - Slot content

    private var leadingIcon: some View {
        DesignSystem.Icons.Bell.regular24.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundStyle(DesignSystem.Color.iconInverse)
            .frame(width: 40, height: 40)
            .background(DesignSystem.Color.bgInverse, in: Circle())
    }

    private var circlePlaceholder: some View {
        Circle()
            .fill(DesignSystem.Color.bgTertiary)
            .frame(width: 24, height: 24)
    }

    private var protectedByRow: some View {
        HStack(spacing: 6) {
            Text("Protected by Tangem Security")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            DesignSystem.Icons.ShieldCheckmark.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundStyle(DesignSystem.Color.iconStatusInfo)
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Title").font(.caption).foregroundStyle(.secondary)
                TextField("Title", text: $titleInput, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                Text("Description").font(.caption).foregroundStyle(.secondary)
                TextField("Description", text: $descriptionInput, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
            }

            pickerRow(title: "Variant", cases: TangemMessageBannerVariant.allCases, binding: $variant) {
                String(describing: $0)
            }
            .pickerStyle(.menu)

            pickerRow(title: "Content align", cases: TangemMessageBannerContentAlign.allCases, binding: $contentAlign) {
                String(describing: $0)
            }
            .pickerStyle(.segmented)

            pickerRow(title: "Background", cases: PreviewBackground.allCases, binding: $background) { $0.rawValue }
                .pickerStyle(.segmented)

            VStack(spacing: 8) {
                Toggle("glowRing", isOn: $hasGlowRing)
                Toggle("description", isOn: $hasDescription)
                Toggle("secondaryButton", isOn: $hasSecondaryButton)
                Toggle("primaryButton", isOn: $hasPrimaryButton)
                Toggle("closeButton", isOn: $hasCloseButton)
                Toggle("slotStart", isOn: $hasSlotStart)
                Toggle("slotEnd", isOn: $hasSlotEnd)
                Toggle("extraContent", isOn: $hasExtraContent)
                Toggle("custom text", isOn: $customText)
                Toggle("focus ring", isOn: $focused)
                Toggle("dark mode", isOn: $darkMode)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Title line limit").font(.caption).foregroundStyle(.secondary)
                Picker("Title line limit", selection: $titleLineLimit) {
                    ForEach(1 ... 5, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Description line limit").font(.caption).foregroundStyle(.secondary)
                Picker("Description line limit", selection: $descriptionLineLimit) {
                    ForEach(1 ... 5, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Dynamic Type").font(.caption).foregroundStyle(.secondary)
                Picker("Dynamic Type", selection: $typeSize) {
                    ForEach(DynamicTypeSize.allCases, id: \.self) { size in
                        Text(String(describing: size)).tag(size)
                    }
                }
            }
        }
    }

    private func pickerRow<Value: Hashable>(
        title: String,
        cases: [Value],
        binding: Binding<Value>,
        label: @escaping (Value) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Picker(title, selection: binding) {
                ForEach(cases, id: \.self) { value in
                    Text(label(value)).tag(value)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Showcase") {
    TangemMessageBannerShowcase()
}

#Preview("Variants") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(TangemMessageBannerVariant.allCases, id: \.self) { variant in
                TangemMessageBanner(title: String(describing: variant), description: "Description")
                    .variant(variant)
                    .secondaryButton(.init(title: "Label", action: {}))
                    .primaryButton(.init(title: "Label", action: {}))
            }
        }
        .padding()
    }
    .background(DesignSystem.Color.bgPrimary)
}

#Preview("Content align") {
    VStack(spacing: 16) {
        ForEach(TangemMessageBannerContentAlign.allCases, id: \.self) { align in
            TangemMessageBanner(title: "Content align \(String(describing: align))", description: "Share Tangem, give 10% OFF, and earn 10 USDT.")
                .contentAlign(align)
                .secondaryButton(.init(title: "Later", action: {}))
                .primaryButton(.init(title: "Invite", action: {}))
        }
    }
    .padding()
    .background(DesignSystem.Color.bgPrimary)
}

#Preview("Slots & close") {
    VStack(spacing: 16) {
        TangemMessageBanner(title: "Title", description: "Description")
            .closeButton(accessibilityLabel: "Dismiss") {}
            .secondaryButton(.init(title: "Label", action: {}))
            .primaryButton(.init(title: "Label", action: {}))

        TangemMessageBanner(title: "Invite friends. Earn 10 USDT.", description: "Share Tangem, give 10% OFF, and earn 10 USDT.")
            .slotStart {
                DesignSystem.Icons.Bell.regular24.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(DesignSystem.Color.iconInverse)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Color.bgInverse, in: Circle())
            }
            .primaryButton(.init(title: "Invite friends", action: {}))
    }
    .padding()
    .background(DesignSystem.Color.bgPrimary)
}
