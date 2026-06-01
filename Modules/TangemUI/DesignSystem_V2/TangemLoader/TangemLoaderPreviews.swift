//
//  TangemLoaderPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemLoaderShowcase: View {
    @State private var size: TangemLoader.Size = .size24
    @State private var color: ColorOption = .primary

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            pickerSection
                .padding()

            color.background
                .overlay {
                    TangemLoader()
                        .loaderSize(size)
                        .loaderColor(color.value)
                }
        }
    }

    private var pickerSection: some View {
        VStack(spacing: 8) {
            Picker("Size", selection: $size) {
                Text("12").tag(TangemLoader.Size.size12)
                Text("16").tag(TangemLoader.Size.size16)
                Text("20").tag(TangemLoader.Size.size20)
                Text("24").tag(TangemLoader.Size.size24)
                Text("28").tag(TangemLoader.Size.size28)
                Text("32").tag(TangemLoader.Size.size32)
            }
            .pickerStyle(.segmented)

            Picker("Color", selection: $color) {
                Text("primary").tag(ColorOption.primary)
                Text("secondary").tag(ColorOption.secondary)
                Text("tertiary").tag(ColorOption.tertiary)
                Text("brand").tag(ColorOption.brand)
                Text("inverse").tag(ColorOption.inverse)
            }
            .pickerStyle(.segmented)
        }
    }

    enum ColorOption: Hashable {
        case primary
        case secondary
        case tertiary
        case brand
        case inverse

        var value: Color {
            switch self {
            case .primary: DesignSystem.Tokens.Theme.Icon.primary
            case .secondary: DesignSystem.Tokens.Theme.Icon.secondary
            case .tertiary: DesignSystem.Tokens.Theme.Icon.tertiary
            case .brand: DesignSystem.Tokens.Theme.Icon.brand
            case .inverse: DesignSystem.Tokens.Theme.Icon.inverse
            }
        }

        var background: Color {
            switch self {
            case .inverse: DesignSystem.Tokens.Theme.Bg.inverse
            default: DesignSystem.Tokens.Theme.Bg.primary
            }
        }
    }
}

// MARK: - Previews

#if DEBUG

private struct LoaderSizeGalleryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            row(label: "12 pt", size: .size12)
            row(label: "16 pt", size: .size16)
            row(label: "20 pt", size: .size20)
            row(label: "24 pt", size: .size24)
            row(label: "28 pt", size: .size28)
            row(label: "32 pt", size: .size32)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.Tangem.Surface.level1)
    }

    private func row(label: String, size: TangemLoader.Size) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .frame(width: 48, alignment: .leading)

            TangemLoader()
                .loaderSize(size)
        }
    }
}

private struct LoaderColorVariantsView: View {
    var body: some View {
        VStack(spacing: 0) {
            colorRow(label: "primary", color: .Tangem.Graphic.Neutral.primary, bg: Color.Tangem.Surface.level1)
            colorRow(label: "inverse", color: .Tangem.Graphic.Neutral.primaryInverted, bg: Color.black)
            colorRow(label: "static-dark", color: .Tangem.Graphic.Neutral.primaryInvertedConstant, bg: Color.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func colorRow(label: String, color: Color, bg: Color) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .foregroundStyle(color)
                .frame(width: 96, alignment: .leading)

            TangemLoader()
                .loaderColor(color)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg)
    }
}

#Preview("Sizes") {
    LoaderSizeGalleryView()
}

#Preview("Sizes — Dark") {
    LoaderSizeGalleryView()
        .preferredColorScheme(.dark)
}

#Preview("Color Variations") {
    LoaderColorVariantsView()
}

#endif // DEBUG
