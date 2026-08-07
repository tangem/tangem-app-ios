//
//  ForceUpdateGlowBackground.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct ForceUpdateGlowBackground: View {
    let color: Color

    var body: some View {
        ZStack(alignment: .top) {
            Circle()
                .fill(color.opacity(Constants.glowOpacity))
                .frame(size: .init(bothDimensions: Constants.outerGlowSize))
                .blur(radius: Constants.glowBlur)
                .offset(y: Constants.glowOffsetY)

            Circle()
                .fill(color.opacity(Constants.glowOpacity))
                .frame(size: .init(bothDimensions: Constants.innerGlowSize))
                .blur(radius: Constants.glowBlur)
                .offset(y: Constants.glowOffsetY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Color.bgPrimary)
        .ignoresSafeArea()
    }
}

private extension ForceUpdateGlowBackground {
    enum Constants {
        static let glowOpacity: Double = 0.4
        static let outerGlowSize: CGFloat = 533
        static let innerGlowSize: CGFloat = 415
        static let glowBlur: CGFloat = 96
        static let glowOffsetY: CGFloat = -244
    }
}
