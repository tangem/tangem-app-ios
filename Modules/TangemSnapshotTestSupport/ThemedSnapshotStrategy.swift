//
//  ThemedSnapshotStrategy.swift
//  TangemSnapshotTestSupport
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SnapshotTesting
import SwiftUI
import TangemAssets
import UIKit

extension Snapshotting where Value: View, Format == UIImage {
    static func themed(
        _ colorScheme: ColorScheme = .light,
        canvas: SnapshotCanvas = .component,
        layoutDirection: LayoutDirection = .leftToRight,
        dynamicTypeSize: DynamicTypeSize = .large,
        background: Color = DesignSystem.Color.bgPrimary
    ) -> Self {
        let frame = SnapshotFrame(canvas: canvas)

        return Snapshotting<AnyView, UIImage>.image(
            drawHierarchyInKeyWindow: true,
            precision: 1,
            perceptualPrecision: 0.98,
            layout: frame.layout,
            traits: UITraitCollection(traitsFrom: [
                UITraitCollection(displayScale: frame.scale),
                UITraitCollection(displayGamut: .SRGB),
                UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light),
                UITraitCollection(preferredContentSizeCategory: dynamicTypeSize.contentSizeCategory),
                UITraitCollection(layoutDirection: layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight),
            ])
        ).pullback { view in
            AnyView(
                framed(view, safeArea: frame.safeArea, background: background)
                    .environment(\.colorScheme, colorScheme)
                    .environment(\.layoutDirection, layoutDirection)
                    .environment(\.dynamicTypeSize, dynamicTypeSize)
                    .environment(\.locale, Locale(identifier: "en_US"))
                    .environment(\.timeZone, TimeZone(secondsFromGMT: 0)!)
                    .environment(\.displayScale, frame.scale)
                    .transaction {
                        $0.animation = nil
                        $0.disablesAnimations = true
                    }
            )
        }
    }
}

extension Dictionary where Key == String {
    static func themed<V: View>(
        canvases: [SnapshotCanvas] = [.component],
        colorSchemes: [ColorScheme] = [.light, .dark],
        layoutDirection: LayoutDirection = .leftToRight,
        dynamicTypeSize: DynamicTypeSize = .large,
        background: Color = DesignSystem.Color.bgPrimary
    ) -> Self where Value == Snapshotting<V, UIImage> {
        var strategies = Self()
        for canvas in canvases {
            for colorScheme in colorSchemes {
                let theme = colorScheme == .dark ? "dark" : "light"
                let key = switch canvas {
                case .screen(let device): "\(device.rawValue)-\(theme)"
                case .component, .fixed: theme
                }
                strategies[key] = .themed(
                    colorScheme,
                    canvas: canvas,
                    layoutDirection: layoutDirection,
                    dynamicTypeSize: dynamicTypeSize,
                    background: background
                )
            }
        }
        return strategies
    }
}

private extension DynamicTypeSize {
    var contentSizeCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: .extraSmall
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .extraLarge
        case .xxLarge: .extraExtraLarge
        case .xxxLarge: .extraExtraExtraLarge
        case .accessibility1: .accessibilityMedium
        case .accessibility2: .accessibilityLarge
        case .accessibility3: .accessibilityExtraLarge
        case .accessibility4: .accessibilityExtraExtraLarge
        case .accessibility5: .accessibilityExtraExtraExtraLarge
        @unknown default: .large
        }
    }
}

private struct SnapshotFrame {
    let layout: SwiftUISnapshotLayout
    let scale: CGFloat
    let safeArea: UIEdgeInsets?

    init(canvas: SnapshotCanvas) {
        switch canvas {
        case .component:
            layout = .sizeThatFits
            scale = 3
            safeArea = nil
        case .screen(let device):
            let config = device.config
            layout = .device(config: ViewImageConfig(safeArea: .zero, size: config.size, traits: config.traits))
            scale = device.scale
            safeArea = config.safeArea
        case .fixed(let width, let height):
            layout = .fixed(width: width, height: height)
            scale = 3
            safeArea = .zero
        }
    }
}

private func framed(_ view: some View, safeArea: UIEdgeInsets?, background: Color) -> AnyView {
    guard let safeArea else {
        return AnyView(
            view
                .fixedSize()
                .padding(8)
                .background(background)
                .ignoresSafeArea()
        )
    }

    let top = safeArea.top
    let bottom = safeArea.bottom

    return AnyView(
        view
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: top)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: bottom)
            }
            .background(background)
            .ignoresSafeArea()
    )
}
