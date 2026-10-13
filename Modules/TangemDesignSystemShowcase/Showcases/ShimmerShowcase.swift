//
//  ShimmerShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct ShimmerShowcase: View {
    @State private var variant: VariantKind = .text
    @State private var textStyle: Shimmer.TextStyle = .body
    @State private var alignment: Shimmer.Alignment = .leading
    @State private var width: CGFloat = 200
    @State private var height: CGFloat = 40
    @State private var isCapsule = true
    @State private var cornerRadius: CGFloat = 0
    @State private var isModifierActive = true
    @State private var isPlaceholderShown = true

    var body: some View {
        DSShowcase("Shimmer") { controls in
            controls.picker("Variant", $variant)

            switch variant {
            case .text:
                controls.picker("Text style", $textStyle)
                controls.picker("Alignment", $alignment, options: [.leading, .center, .trailing])
            case .custom:
                controls.value("Width", $width, in: 40 ... 320, step: 20)
                controls.value("Height", $height, in: 12 ... 120, step: 4)
                controls.toggle("Capsule corner", $isCapsule)
                if !isCapsule {
                    controls.value("Corner radius", $cornerRadius, in: 0 ... 60, step: 2)
                }
            case .fill:
                EmptyView()
            }

            controls.toggle(".shimmering() env active", $isModifierActive)
            controls.toggle(".shimmerPlaceholder shown", $isPlaceholderShown)
        } stage: {
            VStack(alignment: .leading, spacing: 24) {
                Shimmer()
                    .variant(currentVariant)
                    .frame(height: variant == .fill ? 80 : nil)

                modifierSample

                placeholderSample
            }
        } matrix: {
            DSShowcaseGroup("Text variant") {
                DSShowcaseMatrix(rows: Shimmer.TextStyle.allCases, columns: [Shimmer.Alignment.leading, .center, .trailing]) { style, alignment in
                    Shimmer()
                        .variant(.text(style: style, alignment: alignment))
                        .frame(width: 120)
                }
            }

            DSShowcaseGroup("List skeleton") {
                listSkeleton
            }

            DSShowcaseGroup("Placeholder") {
                placeholderMatrix
            }
        }
    }

    private var currentVariant: Shimmer.Variant {
        switch variant {
        case .text:
            .text(style: textStyle, alignment: alignment)
        case .custom:
            .custom(width: width, height: height, cornerRadius: isCapsule ? nil : cornerRadius)
        case .fill:
            .custom()
        }
    }

    private var modifierSample: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("$69,786.00")
                .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
            Text("Total balance")
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .shimmering()
        .environment(\.isShimmerActive, isModifierActive)
    }

    private var placeholderSample: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(DesignSystem.Color.bgTertiary)
                .frame(width: 36, height: 36)
                .shimmerPlaceholder(isPlaceholderShown, variant: .custom(width: 36, height: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text("Ethereum")
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .shimmerPlaceholder(isPlaceholderShown)

                Text("ETH")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .shimmerPlaceholder(isPlaceholderShown, variant: .custom(width: 60, height: 12))
            }
        }
    }

    private var placeholderMatrix: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content frame")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .shimmerPlaceholder(true)

            Text("Content frame, radius 2")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .shimmerPlaceholder(true, variant: .custom(cornerRadius: 2))

            Text("")
                .shimmerPlaceholder(true, variant: .custom(width: 80, height: 16))

            Text("Wider than block")
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .shimmerPlaceholder(true, variant: .custom(width: 40, height: 12))
        }
    }

    private var listSkeleton: some View {
        VStack(spacing: 12) {
            ForEach(0 ..< 3, id: \.self) { _ in
                HStack(spacing: 12) {
                    Shimmer()
                        .variant(.custom(width: 40, height: 40, cornerRadius: 20))
                    VStack(alignment: .leading, spacing: 6) {
                        Shimmer().variant(.text(style: .body))
                        Shimmer().variant(.text(style: .caption))
                    }
                }
            }
        }
    }
}

private extension ShimmerShowcase {
    enum VariantKind: CaseIterable {
        case text
        case custom
        case fill
    }
}
#endif
