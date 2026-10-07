//
//  TangemBadgeShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct TangemBadgeShowcase: View {
    @State private var text = "Staking"
    @State private var size: TangemBadge.Size = .x9
    @State private var shape: TangemBadge.Shape = .rectangular
    @State private var color: TangemBadge.BadgeColor = .blue
    @State private var type: TangemBadge.BadgeType = .solid
    @State private var showIcon = true
    @State private var iconPosition: TangemBadge.IconPosition = .leading

    var body: some View {
        DSShowcase("TangemBadge") { controls in
            controls.text("Text", $text)
            controls.picker("Size", $size, options: Self.sizes)
            controls.picker("Shape", $shape, options: Self.shapes)
            controls.picker("Color", $color, options: Self.colors)
            controls.picker("Type", $type, options: Self.types)
            controls.toggle("Icon", $showIcon)
            if showIcon {
                controls.picker("Icon position", $iconPosition, options: Self.iconPositions)
            }
        } stage: {
            TangemBadge(text: text, size: size)
                .shape(shape)
                .color(color)
                .type(type)
                .icon(showIcon ? Assets.star.image : nil)
                .iconPosition(iconPosition)
        } matrix: {
            DSShowcaseGroup("Color × Type") {
                DSShowcaseMatrix(rows: Self.types, columns: Self.colors) { type, color in
                    TangemBadge(text: "APY 4.2%", size: .x9)
                        .color(color)
                        .type(type)
                }
            }

            DSShowcaseGroup("Size") {
                DSShowcaseMatrix(rows: Self.sizes, columns: SizeSample.allCases) { size, sample in
                    sizeSample(sample, size: size)
                }
            }

            DSShowcaseGroup("Constrained width") {
                DSShowcaseMatrix(rows: WidthSample.allCases) { sample in
                    widthSample(sample)
                }
            }
        }
    }

    private func sizeSample(_ sample: SizeSample, size: TangemBadge.Size) -> some View {
        TangemBadge(text: "New", size: size)
            .icon(sample == .icon ? Assets.star.image : nil)
            .shape(sample == .rounded ? .rounded : .rectangular)
            .color(.blue)
            .type(.solid)
    }

    private func widthSample(_ sample: WidthSample) -> some View {
        TangemBadge(text: "Rewards are paid out every 24 hours", size: .x9)
            .icon(sample == .iconWidth120 ? Assets.star.image : nil)
            .shape(sample == .roundedWidth100 ? .rounded : .rectangular)
            .color(sample.color)
            .type(sample.type)
            .frame(maxWidth: sample.maxWidth)
    }
}

private extension TangemBadgeShowcase {
    static var sizes: [TangemBadge.Size] { [.x4, .x6, .x9] }
    static var shapes: [TangemBadge.Shape] { [.rectangular, .rounded] }
    static var colors: [TangemBadge.BadgeColor] { [.blue, .red, .yellow, .gray] }
    static var types: [TangemBadge.BadgeType] { [.solid, .tinted, .outline] }
    static var iconPositions: [TangemBadge.IconPosition] { [.leading, .trailing] }

    enum SizeSample: CaseIterable {
        case plain
        case icon
        case rounded
    }

    enum WidthSample: CaseIterable {
        case intrinsic
        case width150
        case width100
        case iconWidth120
        case roundedWidth100

        var maxWidth: CGFloat? {
            switch self {
            case .intrinsic: nil
            case .width150: 150
            case .width100, .roundedWidth100: 100
            case .iconWidth120: 120
            }
        }

        var color: TangemBadge.BadgeColor {
            switch self {
            case .intrinsic, .width150, .width100: .blue
            case .iconWidth120: .red
            case .roundedWidth100: .gray
            }
        }

        var type: TangemBadge.BadgeType {
            switch self {
            case .intrinsic, .width150, .width100: .solid
            case .iconWidth120: .tinted
            case .roundedWidth100: .outline
            }
        }
    }
}
#endif
