//
//  TangemFadePreviews.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Showcase

public struct TangemFadeShowcase: View {
    @State private var variant: TangemFade.Variant = .soft
    @State private var position: TangemFade.Position = .bottom
    @State private var background: BackgroundOption = .primary
    @State private var isBlurEnabled = false
    @State private var isDarkMode = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            previewArea
                .padding(.vertical, 16)
                .environment(\.colorScheme, isDarkMode ? .dark : .light)

            controls
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Color.bgPrimary)
    }

    private var previewArea: some View {
        RainbowBackdrop()
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .overlay(alignment: position.alignment) {
                TangemFade(position: position)
                    .variant(variant)
                    .blurred(isBlurEnabled)
                    .backgroundColor(background.color)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
    }

    private var controls: some View {
        ScrollView {
            VStack(spacing: 12) {
                Picker("Variant", selection: $variant) {
                    Text("soft").tag(TangemFade.Variant.soft)
                    Text("hard").tag(TangemFade.Variant.hard)
                }
                .pickerStyle(.segmented)

                Picker("Position", selection: $position) {
                    Text("top").tag(TangemFade.Position.top)
                    Text("bottom").tag(TangemFade.Position.bottom)
                }
                .pickerStyle(.segmented)

                Picker("Background", selection: $background) {
                    Text("primary").tag(BackgroundOption.primary)
                    Text("secondary").tag(BackgroundOption.secondary)
                    Text("inverse").tag(BackgroundOption.inverse)
                }
                .pickerStyle(.segmented)

                Toggle("Blur", isOn: $isBlurEnabled)

                Toggle("Dark mode", isOn: $isDarkMode)
            }
            .padding()
        }
    }

    enum BackgroundOption: Hashable {
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
}

private extension TangemFade.Position {
    var alignment: Alignment {
        switch self {
        case .top: .top
        case .bottom: .bottom
        }
    }
}

// MARK: - Rainbow backdrop

private struct RainbowBackdrop: View {
    private static let tile: CGFloat = 160

    private static let bands: [Color] = [
        Color(red: 0xFF / 255.0, green: 0x17 / 255.0, blue: 0x44 / 255.0),
        Color(red: 0xFF / 255.0, green: 0x91 / 255.0, blue: 0x00 / 255.0),
        Color(red: 0xFF / 255.0, green: 0xEA / 255.0, blue: 0x00 / 255.0),
        Color(red: 0x00 / 255.0, green: 0xE6 / 255.0, blue: 0x76 / 255.0),
        Color(red: 0x00 / 255.0, green: 0xB8 / 255.0, blue: 0xD4 / 255.0),
        Color(red: 0x29 / 255.0, green: 0x62 / 255.0, blue: 0xFF / 255.0),
        Color(red: 0xD5 / 255.0, green: 0x00 / 255.0, blue: 0xF9 / 255.0),
    ]

    var body: some View {
        Canvas { context, size in
            let tileCount = Int(ceil((size.width + size.height) / Self.tile)) + 1
            let bandCount = CGFloat(Self.bands.count)

            var stops: [Gradient.Stop] = []
            for tileIndex in 0 ..< tileCount {
                for (bandIndex, color) in Self.bands.enumerated() {
                    let start = (CGFloat(tileIndex) + CGFloat(bandIndex) / bandCount) / CGFloat(tileCount)
                    let end = (CGFloat(tileIndex) + CGFloat(bandIndex + 1) / bandCount) / CGFloat(tileCount)
                    stops.append(.init(color: color, location: start))
                    stops.append(.init(color: color, location: end))
                }
            }

            let shading = GraphicsContext.Shading.linearGradient(
                Gradient(stops: stops),
                startPoint: .zero,
                endPoint: CGPoint(x: CGFloat(tileCount) * Self.tile, y: CGFloat(tileCount) * Self.tile)
            )
            context.fill(Path(CGRect(origin: .zero, size: size)), with: shading)
        }
    }
}

// MARK: - Previews

private struct FadeGalleryView: View {
    var body: some View {
        VStack(spacing: 16) {
            row(title: "soft / top", variant: .soft, position: .top)
            row(title: "soft / bottom", variant: .soft, position: .bottom)
            row(title: "hard / top", variant: .hard, position: .top)
            row(title: "hard / bottom", variant: .hard, position: .bottom)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary)
    }

    private func row(title: String, variant: TangemFade.Variant, position: TangemFade.Position) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundStyle(DesignSystem.Color.textPrimary)

            DesignSystem.Color.bgAccentBlue
                .frame(height: 120)
                .overlay(alignment: position == .top ? .top : .bottom) {
                    TangemFade(position: position)
                        .variant(variant)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview("Gallery") {
    FadeGalleryView()
}

#Preview("Gallery — Dark") {
    FadeGalleryView()
        .preferredColorScheme(.dark)
}

#Preview("Showcase") {
    TangemFadeShowcase()
}
