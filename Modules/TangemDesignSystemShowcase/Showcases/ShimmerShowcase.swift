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

            controls.toggle(".tangemShimmer() active", $isModifierActive)
        } stage: {
            VStack(alignment: .leading, spacing: 24) {
                Shimmer()
                    .variant(currentVariant)
                    .frame(height: variant == .fill ? 80 : nil)

                modifierSample
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
        .tangemShimmer()
        .environment(\.isShimmerActive, isModifierActive)
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
