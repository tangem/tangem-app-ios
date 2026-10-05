//
//  ModalSurface.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import BlurSwiftUI

struct ModalBackgroundModifier: ViewModifier {
    let size: ModalSize

    func body(content: Content) -> some View {
        content.presentationBackground {
            ModalSurface(isExpanded: size == .full)
        }
    }
}

struct ModalSurface: View {
    let isExpanded: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        surface
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var surface: some View {
        if isExpanded || reduceTransparency {
            Self.fill(isExpanded: isExpanded, reduceTransparency: reduceTransparency)
        } else if #available(iOS 26.0, *) {
            DesignSystem.Color.materialModalTintGlass
        } else {
            VariableBlur(direction: .down)
                .maximumBlurRadius(32)
                .dimmingTintColor(nil)
                .dimmingAlpha(.constant(alpha: 0))
                .dimmingOvershoot(nil)
                .overlay { Self.fill(isExpanded: false, reduceTransparency: false) }
        }
    }

    /// The color the surface lays over the sheet's glass on iOS 26 and later, and over its own blur below.
    static func fill(isExpanded: Bool, reduceTransparency: Bool) -> Color {
        if isExpanded {
            return DesignSystem.Color.bgPrimary
        }

        if reduceTransparency {
            return DesignSystem.Color.materialModalFillSolid
        }

        if #available(iOS 26.0, *) {
            return DesignSystem.Color.materialModalTintGlass
        }

        return DesignSystem.Color.materialModalFillBlur
    }
}
