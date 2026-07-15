//
//  TangemCalloutPreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemCalloutShowcase: View {
    @State private var colorScheme: ColorScheme = .light
    @State private var dynamicTypeSize: DynamicTypeSize = .medium

    @State private var arrowAlignment: TangemCallout.ArrowAlignment = .top
    @State private var paletteOption: PaletteOption = .green
    @State private var showIcon = true

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            pickerSection

            Spacer()

            preview

            Spacer()
        }
        .padding()
        .dynamicTypeSize(dynamicTypeSize)
        .background(Color.Tangem.Surface.level1)
        .environment(\.colorScheme, colorScheme)
    }

    private var pickerSection: some View {
        VStack(spacing: 8) {
            Picker("ArrowAlignment", selection: $arrowAlignment) {
                Text("top").tag(TangemCallout.ArrowAlignment.top)
                Text("bottom").tag(TangemCallout.ArrowAlignment.bottom)
            }
            .pickerStyle(.segmented)

            Picker("Color", selection: $paletteOption) {
                Text("green").tag(PaletteOption.green)
                Text("gray").tag(PaletteOption.gray)
                Text("blue").tag(PaletteOption.blue)
            }
            .pickerStyle(.segmented)

            Toggle("Show Icon", isOn: $showIcon)

            Picker("ColorSheme", selection: $colorScheme) {
                Text("light").tag(ColorScheme.light)
                Text("dark").tag(ColorScheme.dark)
            }
            .pickerStyle(.segmented)

            Picker("DynamicTypeSize", selection: $dynamicTypeSize) {
                Text("medium").tag(DynamicTypeSize.medium)
                Text("xxxLarge").tag(DynamicTypeSize.xxxLarge)
                Text("xSmall").tag(DynamicTypeSize.xSmall)
            }
            .pickerStyle(.segmented)
        }
    }

    private var preview: some View {
        TangemCallout(
            text: "Callout",
            arrowAlignment: arrowAlignment,
            action: .init(icon: Assets.star.image, closure: {})
        )
        .colorPalette(paletteOption.palette)
        .icon(showIcon ? Assets.star.image : nil)
    }
}

// MARK: - PaletteOption

private extension TangemCalloutShowcase {
    enum PaletteOption {
        case green
        case gray
        case blue

        var palette: TangemCallout.ColorPalette {
            switch self {
            case .green: .green
            case .gray: .gray
            case .blue: .blue
            }
        }
    }
}

// MARK: - Previews

#Preview("Interactive Demo") {
    TangemCalloutShowcase()
}

#Preview("All Palettes") {
    VStack(spacing: 24) {
        TangemCallout(
            text: "Green palette",
            arrowAlignment: .top,
            action: .init(icon: Assets.star.image, closure: {})
        )
        .colorPalette(.green)
        .icon(Assets.star.image)

        TangemCallout(
            text: "Gray palette",
            arrowAlignment: .top,
            action: .init(icon: Assets.star.image, closure: {})
        )
        .colorPalette(.gray)
        .icon(Assets.star.image)

        TangemCallout(
            text: "Blue palette",
            arrowAlignment: .top,
            action: .init(icon: Assets.star.image, closure: {})
        )
        .colorPalette(.blue)
        .icon(Assets.star.image)
    }
    .padding()
    .background(Color.Tangem.Surface.level1)
}
