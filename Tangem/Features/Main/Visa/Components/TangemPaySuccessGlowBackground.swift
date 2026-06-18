//
//  TangemPaySuccessGlowBackground.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TangemPaySuccessGlowBackground: View {
    var body: some View {
        ZStack(alignment: .top) {
            Circle()
                .fill(Color(hex: Constants.outerGlowHex).opacity(Constants.glowOpacity))
                .frame(width: Constants.outerGlowSize, height: Constants.outerGlowSize)
                .blur(radius: Constants.glowBlur)
                .offset(y: Constants.glowOffsetY)

            Circle()
                .fill(Color(hex: Constants.innerGlowHex).opacity(Constants.glowOpacity))
                .frame(width: Constants.innerGlowSize, height: Constants.innerGlowSize)
                .blur(radius: Constants.glowBlur)
                .offset(y: Constants.glowOffsetY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Color.bgPrimary)
        .ignoresSafeArea()
    }
}

private extension TangemPaySuccessGlowBackground {
    enum Constants {
        static let outerGlowHex = "34DF12"
        static let innerGlowHex = "DFAF12"
        static let glowOpacity: Double = 0.32
        static let outerGlowSize: CGFloat = 533
        static let innerGlowSize: CGFloat = 415
        static let glowBlur: CGFloat = 96
        static let glowOffsetY: CGFloat = -244
    }
}
