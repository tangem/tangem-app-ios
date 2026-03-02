//
//  TangemBadgePreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemBadgeShowcase: View {
    @State private var size: TangemBadge.Size = .x9
    @State private var shape: TangemBadge.Shape = .rectangular
    @State private var color: TangemBadge.BadgeColor = .blue
    @State private var type: TangemBadge.BadgeType = .solid
    @State private var showIcon = true
    @State private var iconPosition: TangemBadge.IconPosition = .leading

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
                Text("x4").tag(TangemBadge.Size.x4)
                Text("x6").tag(TangemBadge.Size.x6)
                Text("x9").tag(TangemBadge.Size.x9)
            }
            .pickerStyle(.segmented)

            Picker("Shape", selection: $shape) {
                Text("default").tag(TangemBadge.Shape.rectangular)
                Text("rounded").tag(TangemBadge.Shape.rounded)
            }
            .pickerStyle(.segmented)

            Picker("Color", selection: $color) {
                Text("blue").tag(TangemBadge.BadgeColor.blue)
                Text("red").tag(TangemBadge.BadgeColor.red)
                Text("gray").tag(TangemBadge.BadgeColor.gray)
            }
            .pickerStyle(.segmented)

            Picker("Type", selection: $type) {
                Text("solid").tag(TangemBadge.BadgeType.solid)
                Text("tinted").tag(TangemBadge.BadgeType.tinted)
                Text("outline").tag(TangemBadge.BadgeType.outline)
            }
            .pickerStyle(.segmented)

            Toggle("Show Icon", isOn: $showIcon)

            if showIcon {
                Picker("Icon Position", selection: $iconPosition) {
                    Text("leading").tag(TangemBadge.IconPosition.leading)
                    Text("trailing").tag(TangemBadge.IconPosition.trailing)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var badgePreview: some View {
        TangemBadge(text: "Badge", size: size)
            .shape(shape)
            .color(color)
            .type(type)
            .icon(showIcon ? Assets.star.image : nil)
            .iconPosition(iconPosition)
    }
}

// MARK: - Previews

#if DEBUG

private typealias _Badge = TangemBadge

// MARK: - Matrix Preview

private struct BadgeMatrixView: View {
    let colors: [_Badge.BadgeColor] = [.blue, .red, .gray]
    let types: [_Badge.BadgeType] = [.solid, .tinted, .outline]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(types, id: \.self) { type in
                VStack(alignment: .leading, spacing: 8) {
                    Text(typeName(type))
                        .font(.headline)

                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            _Badge(text: colorName(color), size: .x9)
                                .color(color)
                                .type(type)
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func typeName(_ type: _Badge.BadgeType) -> String {
        switch type {
        case .solid: "Solid"
        case .tinted: "Tinted"
        case .outline: "Outline"
        }
    }

    private func colorName(_ color: _Badge.BadgeColor) -> String {
        switch color {
        case .blue: "Blue"
        case .red: "Red"
        case .gray: "Gray"
        }
    }
}

// MARK: - Size Comparison

private struct BadgeSizeComparisonView: View {
    let sizes: [_Badge.Size] = [.x4, .x6, .x9]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sizes, id: \.self) { size in
                HStack(spacing: 12) {
                    Text(sizeName(size))
                        .frame(width: 40, alignment: .leading)

                    _Badge(text: "Badge", size: size)
                        .color(.blue)
                        .type(.solid)

                    _Badge(text: "Badge", size: size)
                        .icon(Assets.star.image)
                        .color(.blue)
                        .type(.solid)

                    _Badge(text: "Badge", size: size)
                        .shape(.rounded)
                        .color(.blue)
                        .type(.solid)
                }
            }
        }
        .padding()
    }

    private func sizeName(_ size: _Badge.Size) -> String {
        switch size {
        case .x4: "x4"
        case .x6: "x6"
        case .x9: "x9"
        }
    }
}

// MARK: - Constrained Width

private struct BadgeConstrainedWidthView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Unconstrained (intrinsic size)")
                    .font(.headline)

                _Badge(text: "This is a very long badge text", size: .x9)
                    .color(.blue)
                    .type(.solid)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Constrained to 150pt")
                    .font(.headline)

                _Badge(text: "This is a very long badge text", size: .x9)
                    .color(.blue)
                    .type(.solid)
                    .frame(maxWidth: 150)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Constrained to 100pt")
                    .font(.headline)

                _Badge(text: "This is a very long badge text", size: .x9)
                    .color(.blue)
                    .type(.solid)
                    .frame(maxWidth: 100)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("With icon, constrained to 120pt")
                    .font(.headline)

                _Badge(text: "Long text with icon", size: .x9)
                    .icon(Assets.star.image)
                    .color(.red)
                    .type(.tinted)
                    .frame(maxWidth: 120)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Rounded shape, constrained to 100pt")
                    .font(.headline)

                _Badge(text: "This is a very long badge text", size: .x9)
                    .shape(.rounded)
                    .color(.gray)
                    .type(.outline)
                    .frame(maxWidth: 100)
            }
        }
        .padding()
    }
}

#Preview("Interactive Demo") {
    TangemBadgeShowcase()
}

#Preview("Color & Type Matrix") {
    BadgeMatrixView()
}

#Preview("Size Comparison") {
    BadgeSizeComparisonView()
}

#Preview("Dark Mode") {
    BadgeMatrixView()
        .preferredColorScheme(.dark)
}

#Preview("Dynamic Type - Large") {
    BadgeSizeComparisonView()
        .dynamicTypeSize(.xxxLarge)
}

#Preview("Dynamic Type - Small") {
    BadgeSizeComparisonView()
        .dynamicTypeSize(.xSmall)
}

#Preview("Constrained Width") {
    BadgeConstrainedWidthView()
}

#endif // DEBUG
