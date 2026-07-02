//
//  GlowRingShowcase.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct GlowRingShowcase: View {
    @State private var appearance: GlowRingAppearance = .magic
    @State private var cornerRadius: CGFloat = 24
    @State private var isAnimating = true

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                interactiveSection
                forYouBannerSection
                appearanceGallerySection
            }
            .padding(24)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

private extension GlowRingShowcase {
    // MARK: - Sections

    var interactiveSection: some View {
        section(title: "Interactive") {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Appearance", selection: $appearance) {
                    ForEach(GlowRingAppearance.allCases, id: \.self) { appearance in
                        Text(title(for: appearance)).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)

                Stepper("Corner radius: \(Int(cornerRadius))", value: $cornerRadius, in: 0 ... 48, step: 2)
                Toggle("isAnimating", isOn: $isAnimating)

                banner(
                    title: title(for: appearance),
                    subtitle: "Reconfigure with the controls above",
                    cornerRadius: cornerRadius
                )
                .glowRing(appearance, cornerRadius: cornerRadius, isAnimating: isAnimating)
            }
        }
    }

    /// The ForYou entrance banner rebuilt from primitives — the component's first real consumer.
    var forYouBannerSection: some View {
        section(title: "For You banner — .glowRing(.magic)") {
            banner(
                title: "For You",
                subtitle: "Review portfolio and explore earn opportunities",
                cornerRadius: 24
            )
            .glowRing(.magic)
        }
    }

    var appearanceGallerySection: some View {
        section(title: "Appearances") {
            VStack(spacing: 16) {
                ForEach(GlowRingAppearance.allCases, id: \.self) { appearance in
                    banner(
                        title: title(for: appearance),
                        subtitle: "\(title(for: appearance)) glow ring",
                        cornerRadius: 24
                    )
                    .glowRing(appearance)
                }

                Text("magic morphs between two palettes; success / error / warning / info are static.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Building blocks

    func banner(title: String, subtitle: String, cornerRadius: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 12) {
            DesignSystem.Icons.PieChart.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(DesignSystem.Color.iconPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                Text(subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: cornerRadius))
    }

    func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(DesignSystem.Color.bgOpaquePrimary)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(DesignSystem.Color.borderPrimary, lineWidth: 1)
            )
    }

    // MARK: - Helpers

    func title(for appearance: GlowRingAppearance) -> String {
        String(describing: appearance).capitalized
    }

    func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }
}
