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
    private enum SlotPreset: String, CaseIterable {
        case none
        case leading
        case close
        case leadingClose
        case extra

        var label: String {
            switch self {
            case .none: "none"
            case .leading: "leading"
            case .close: "close"
            case .leadingClose: "lead+close"
            case .extra: "extra"
            }
        }
    }

    @State private var variant: TangemMessageBannerVariant = .default
    @State private var contentAlign: TangemMessageBannerContentAlign = .start
    @State private var slotPreset: SlotPreset = .none
    @State private var hasGlowRing = true
    @State private var hasDescription = true
    @State private var hasSecondaryButton = true
    @State private var hasPrimaryButton = true
    @State private var darkMode = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                previewBanner
                    .padding(.vertical, 24)

                controls
            }
            .padding()
        }
        .background(DesignSystem.Color.bgPrimary)
        .environment(\.colorScheme, darkMode ? .dark : .light)
    }

    @ViewBuilder
    private var previewBanner: some View {
        let base = TangemMessageBanner(
            title: "Would you predict?",
            description: hasDescription ? "France will win FIFA 2026" : nil
        )

        switch slotPreset {
        case .none:
            configured(base)
        case .leading:
            configured(base.slotStart { leadingIcon })
        case .close:
            configured(base.closeButton(accessibilityLabel: "Dismiss") {})
        case .leadingClose:
            configured(base.slotStart { leadingIcon }.closeButton(accessibilityLabel: "Dismiss") {})
        case .extra:
            configured(base.extraBottom { protectedByRow })
        }
    }

    private func configured<S: View, E: View, X: View>(
        _ banner: TangemMessageBanner<S, E, X>
    ) -> TangemMessageBanner<S, E, X> {
        banner
            .variant(variant)
            .contentAlign(contentAlign)
            .showGlowRing(hasGlowRing)
            .secondaryButton(hasSecondaryButton ? .init(title: "Yes", action: {}) : nil)
            .primaryButton(hasPrimaryButton ? .init(title: "Oh, yes", action: {}) : nil)
    }

    private var leadingIcon: some View {
        DesignSystem.Icons.Bell.regular24.image
            .renderingMode(.template)
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundStyle(DesignSystem.Color.iconInverse)
            .frame(width: 40, height: 40)
            .background(DesignSystem.Color.bgInverse, in: Circle())
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

    @ViewBuilder
    private var controls: some View {
        pickerRow(title: "variant", cases: TangemMessageBannerVariant.allCases, binding: $variant) {
            String(describing: $0)
        }
        pickerRow(title: "align", cases: TangemMessageBannerContentAlign.allCases, binding: $contentAlign) {
            String(describing: $0)
        }
        pickerRow(title: "slots", cases: SlotPreset.allCases, binding: $slotPreset) { $0.label }

        Toggle("glow ring", isOn: $hasGlowRing)
        Toggle("description", isOn: $hasDescription)
        Toggle("secondary button", isOn: $hasSecondaryButton)
        Toggle("primary button", isOn: $hasPrimaryButton)
        Toggle("dark mode", isOn: $darkMode)
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
