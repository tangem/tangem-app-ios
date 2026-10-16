//
//  Button+Style.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension Button {
    struct Style: ButtonStyle {
        let content: Content
        let size: Size
        let styleType: StyleType
        let horizontalLayout: HorizontalLayout

        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.buttonPaintsPressOverlay) private var paintsPressOverlay
        @ScaledMetric private var height: CGFloat
        @ScaledMetric private var labelMinWidth: CGFloat
        @ScaledMetric private var horizontalPadding: CGFloat
        @ScaledMetric private var verticalPadding: CGFloat

        init(
            content: Content,
            size: Size,
            styleType: StyleType,
            horizontalLayout: HorizontalLayout
        ) {
            self.content = content
            self.size = size
            self.styleType = styleType
            self.horizontalLayout = horizontalLayout
            _height = ScaledMetric(wrappedValue: size.height, relativeTo: .body)
            _labelMinWidth = ScaledMetric(wrappedValue: size.labelMinWidth, relativeTo: .body)
            _horizontalPadding = ScaledMetric(wrappedValue: size.horizontalPadding, relativeTo: .body)
            _verticalPadding = ScaledMetric(wrappedValue: size.verticalPadding, relativeTo: .body)
        }

        func makeBody(configuration: Configuration) -> some View {
            styledBody(configuration: configuration)
                .opacity(isDimmed ? Constants.disabledOpacity : 1)
        }

        @ViewBuilder
        private func styledBody(configuration: Configuration) -> some View {
            switch styleType {
            case .material(let material):
                materialVariantBody(configuration: configuration, material: material)

            case .brand, .primary, .secondary, .outline, .ghost, .success:
                fixedChromeBody(configuration: configuration)
            }
        }

        @ViewBuilder
        private func materialVariantBody(configuration: Configuration, material: Material) -> some View {
            if #available(iOS 26.0, *), material == .glass {
                paddedLabel(configuration: configuration)
                    .tangemMaterialSurface(in: Capsule(), interactive: isEnabled)
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
                .contentShape(Capsule())
        }

        private func materialBlurBody(configuration: Configuration) -> some View {
            paddedLabel(configuration: configuration)
                .tangemMaterialSurface(in: Capsule())
                .overlay { pressOverlay(isPressed: configuration.isPressed) }
                .contentShape(Capsule())
        }

        // MARK: - Subviews

        private func paddedLabel(configuration: Configuration) -> some View {
            configuration.label
                .font(token: size.typographyToken)
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

        private func pressOverlay(isPressed: Bool) -> some View {
            Capsule()
                .fill(styleType.pressOverlay)
                .opacity(isPressed && isEnabled && paintsPressOverlay ? 1 : 0)
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

        private var isDimmed: Bool {
            !isEnabled && styleType.disabledStyle == .dim
        }

        private var swapsDisabledColors: Bool {
            !isEnabled && styleType.disabledStyle == .swapColors
        }

        private var resolvedBackgroundColor: Color {
            swapsDisabledColors ? DesignSystem.Color.bgDisabled : styleType.backgroundColor
        }

        private var resolvedForegroundColor: Color {
            swapsDisabledColors ? DesignSystem.Color.textTertiary : styleType.foregroundColor
        }
    }
}

// MARK: - Press feedback ownership

extension EnvironmentValues {
    /// Cleared where an ancestor already paints press feedback — interactive Liquid Glass paints its own,
    /// and the style's overlay lands on top of it as a second, differently shaped fill.
    @Entry var buttonPaintsPressOverlay = true
}

// MARK: - Constants

private extension Button.Style {
    enum Constants {
        static let disabledOpacity: CGFloat = 0.4
    }
}
