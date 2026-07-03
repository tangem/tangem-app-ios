//
//  TangemButtonV2+Style.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension TangemButtonV2 {
    struct Style: ButtonStyle {
        let content: Content
        let size: Size
        let styleType: StyleType
        let horizontalLayout: HorizontalLayout
        let isLoading: Bool

        @Environment(\.isEnabled) private var isEnabled
        @ScaledMetric private var height: CGFloat
        @ScaledMetric private var labelMinWidth: CGFloat
        @ScaledMetric private var horizontalPadding: CGFloat
        @ScaledMetric private var verticalPadding: CGFloat

        init(
            content: Content,
            size: Size,
            styleType: StyleType,
            horizontalLayout: HorizontalLayout,
            isLoading: Bool
        ) {
            self.content = content
            self.size = size
            self.styleType = styleType
            self.horizontalLayout = horizontalLayout
            self.isLoading = isLoading
            _height = ScaledMetric(wrappedValue: size.height, relativeTo: .body)
            _labelMinWidth = ScaledMetric(wrappedValue: size.labelMinWidth, relativeTo: .body)
            _horizontalPadding = ScaledMetric(wrappedValue: size.horizontalPadding, relativeTo: .body)
            _verticalPadding = ScaledMetric(wrappedValue: size.verticalPadding, relativeTo: .body)
        }

        @ViewBuilder
        func makeBody(configuration: Configuration) -> some View {
            switch styleType {
            case .material(let material):
                materialVariantBody(configuration: configuration, material: material)

            case .brand, .default, .secondary, .outline, .ghost, .inverse, .positive:
                fixedChromeBody(configuration: configuration)
            }
        }

        @ViewBuilder
        private func materialVariantBody(configuration: Configuration, material: Material) -> some View {
            if #available(iOS 26.0, *), material == .glass {
                paddedLabel(configuration: configuration)
                    .tangemMaterialSurface(in: Capsule(), interactive: isInteractive)
                    .overlay { loadingOverlay }
                    .contentShape(Capsule())
            } else {
                materialBlurBody(configuration: configuration)
            }
        }

        private func fixedChromeBody(configuration: Configuration) -> some View {
            paddedLabel(configuration: configuration)
                .background { Capsule().fill(resolvedBackgroundColor) }
                .overlay { borderOverlay }
                .overlay { pressOverlay(isPressed: configuration.isPressed) }
                .overlay { loadingOverlay }
                .contentShape(Capsule())
        }

        private func materialBlurBody(configuration: Configuration) -> some View {
            paddedLabel(configuration: configuration)
                .tangemMaterialSurface(in: Capsule())
                .overlay { pressOverlay(isPressed: configuration.isPressed) }
                .overlay { loadingOverlay }
                .contentShape(Capsule())
        }

        // MARK: - Subviews

        private func paddedLabel(configuration: Configuration) -> some View {
            configuration.label
                .font(token: size.typographyToken)
                .opacity(isLoading ? 0 : 1)
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.vertical, verticalPadding)
                .frame(minWidth: contentMinWidth, minHeight: height)
                .frame(maxWidth: horizontalLayout.maxWidth)
                .foregroundStyle(resolvedForegroundColor)
        }

        @ViewBuilder
        private var borderOverlay: some View {
            if styleType.borderWidth > 0 {
                Capsule().stroke(styleType.borderColor, lineWidth: styleType.borderWidth)
            }
        }

        @ViewBuilder
        private func pressOverlay(isPressed: Bool) -> some View {
            if isPressed, isInteractive {
                Capsule().fill(styleType.pressOverlay)
            }
        }

        private var isInteractive: Bool {
            isEnabled && !isLoading
        }

        @ViewBuilder
        private var loadingOverlay: some View {
            if isLoading {
                TangemLoader()
                    .loaderSize(size.loaderSize)
                    .loaderColor(styleType.foregroundColor)
            }
        }

        // MARK: - Layout helpers

        private var contentMinWidth: CGFloat {
            switch content {
            case .label: labelMinWidth
            case .iconOnly: height
            }
        }

        private var contentHorizontalPadding: CGFloat {
            switch content {
            case .label: horizontalPadding
            case .iconOnly: 0
            }
        }

        // MARK: - Color/effect resolution

        private var resolvedBackgroundColor: Color {
            isEnabled ? styleType.backgroundColor : DesignSystem.Color.bgDisabled
        }

        private var resolvedForegroundColor: Color {
            isEnabled ? styleType.foregroundColor : DesignSystem.Color.textTertiary
        }
    }
}
