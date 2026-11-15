//
//  MaterialSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI
import TangemUIUtils

enum MaterialSnapshotScenario: String, SnapshotScenario {
    case styles
    case options

    @MainActor
    @ViewBuilder
    var body: some View {
        switch self {
        case .styles:
            SnapshotGrid(styleCases, columns: ShapeSample.allCases.count) { sample in
                surface(sample.shape, style: sample.style)
            }
            .padding(16)
            .background { stripes }
        case .options:
            HStack(spacing: 16) {
                surface(.capsule, style: .default, shadow: nil)
                surface(.capsule, style: .default, isVisible: false)
                surface(.capsule, style: .default, prefersInset: true)
            }
            .padding(16)
            .background { stripes }
        }
    }
}

@MainActor
private extension MaterialSnapshotScenario {
    enum ShapeSample: CaseIterable, Hashable {
        case capsule
        case roundedRectangle
        case circle
    }

    var styleCases: [(style: TangemMaterialStyle, shape: ShapeSample)] {
        [TangemMaterialStyle.default, .inverted].flatMap { style in
            ShapeSample.allCases.map { (style, $0) }
        }
    }

    @ViewBuilder
    func surface(
        _ shape: ShapeSample,
        style: TangemMaterialStyle,
        isVisible: Bool = true,
        shadow: TangemShadowToken? = DesignSystem.Shadow.button,
        prefersInset: Bool = false
    ) -> some View {
        let label = Text("Label")
            .style(
                DesignSystem.Font.bodyMediumToken,
                color: style == .inverted ? DesignSystem.Color.textInversePrimary : DesignSystem.Color.textPrimary
            )

        switch shape {
        case .capsule:
            label
                .frame(width: 120, height: 44)
                .tangemMaterialSurface(in: Capsule(), style: style, isVisible: isVisible, shadow: shadow, prefersInset: prefersInset)
        case .roundedRectangle:
            label
                .frame(width: 120, height: 80)
                .tangemMaterialSurface(
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous),
                    style: style,
                    isVisible: isVisible,
                    shadow: shadow,
                    prefersInset: prefersInset
                )
        case .circle:
            label
                .frame(width: 80, height: 80)
                .tangemMaterialSurface(in: Circle(), style: style, isVisible: isVisible, shadow: shadow, prefersInset: prefersInset)
        }
    }

    var stripes: some View {
        HStack(spacing: 0) {
            ForEach(0 ..< 12, id: \.self) { index in
                index.isMultiple(of: 2) ? DesignSystem.Color.bgBrand : DesignSystem.Color.bgSecondary
            }
        }
    }
}
