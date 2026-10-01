//
//  LoaderShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct LoaderShowcase: View {
    @State private var size: Loader.Size = .size24
    @State private var color: LoaderColor = .primary

    var body: some View {
        DSShowcase("Loader") { controls in
            controls.picker("Size", $size)
            controls.picker("Color", $color)
        } stage: {
            loader(size: size, color: color)
        } matrix: {
            DSShowcaseGroup("Size") {
                DSShowcaseMatrix(rows: Loader.Size.allCases) { size in
                    Loader()
                        .loaderSize(size)
                }
            }

            DSShowcaseGroup("Color") {
                DSShowcaseMatrix(rows: LoaderColor.allCases, columns: [Loader.Size.size16, .size24, .size32]) { color, size in
                    loader(size: size, color: color)
                }
            }
        }
    }

    private func loader(size: Loader.Size, color: LoaderColor) -> some View {
        Loader()
            .loaderSize(size)
            .loaderColor(color.value)
            .padding(12)
            .background(color.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private extension LoaderShowcase {
    enum LoaderColor: CaseIterable {
        case primary
        case secondary
        case tertiary
        case brand
        case inverse
        case staticLight

        var value: Color {
            switch self {
            case .primary: DesignSystem.Color.iconPrimary
            case .secondary: DesignSystem.Color.iconSecondary
            case .tertiary: DesignSystem.Color.iconTertiary
            case .brand: DesignSystem.Color.iconBrand
            case .inverse: DesignSystem.Color.iconInverse
            case .staticLight: DesignSystem.Color.iconStaticLight
            }
        }

        var background: Color {
            switch self {
            case .primary, .secondary, .tertiary, .brand: .clear
            case .inverse: DesignSystem.Color.bgInverse
            case .staticLight: DesignSystem.Color.bgAccentBlue
            }
        }
    }
}
#endif
