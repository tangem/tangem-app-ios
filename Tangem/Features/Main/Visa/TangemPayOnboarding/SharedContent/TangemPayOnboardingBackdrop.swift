//
//  TangemPayOnboardingBackdrop.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation

final class TangemPayOnboardingScrollState: ObservableObject {
    @Published var offset: CGFloat = 0
}

enum TangemPayOnboardingMotion {
    static let parallaxRate: CGFloat = 0.3
    static let dimMaxOpacity: Double = 0.4
    static let dimDistance: CGFloat = 180
    static let pullZoomPerPoint: CGFloat = 0.0008
    static let topScrimOpacity: Double = 0.25
    static let topScrimHeight: CGFloat = 160
}

struct TangemPayOnboardingBackdrop: View {
    @ObservedObject var scroll: TangemPayOnboardingScrollState
    let videoViewModel: LoopingVideoBackgroundViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let offset = scroll.offset
        let lift: CGFloat = reduceMotion ? 0 : max(0, offset) * TangemPayOnboardingMotion.parallaxRate
        let pull: CGFloat = reduceMotion ? 0 : max(0, -offset)
        let zoom: CGFloat = 1 + pull * TangemPayOnboardingMotion.pullZoomPerPoint
        let dimProgress = Double(clamp(offset / TangemPayOnboardingMotion.dimDistance, min: 0, max: 1))

        ZStack(alignment: .top) {
            LoopingVideoBackgroundView(viewModel: videoViewModel)
                .scaleEffect(zoom, anchor: .top)
                .offset(y: -lift)

            Color.black
                .opacity(TangemPayOnboardingMotion.dimMaxOpacity * dimProgress)

            LinearGradient(
                colors: [.black.opacity(TangemPayOnboardingMotion.topScrimOpacity), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: TangemPayOnboardingMotion.topScrimHeight)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct TangemPayOnboardingSheetBackground: View {
    let heroHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: max(0, heroHeight + Metrics.photoFadeEndBelowTitle - Metrics.photoFadeHeight))

            LinearGradient(
                stops: [
                    .init(color: DesignSystem.Color.bgPrimary.opacity(0), location: 0),
                    .init(color: DesignSystem.Color.bgPrimary.opacity(0.3), location: 0.25),
                    .init(color: DesignSystem.Color.bgPrimary.opacity(0.58), location: 0.5),
                    .init(color: DesignSystem.Color.bgPrimary.opacity(0.86), location: 0.75),
                    .init(color: DesignSystem.Color.bgPrimary, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: Metrics.photoFadeHeight)

            DesignSystem.Color.bgPrimary
        }
        .padding(.bottom, -1000)
        .allowsHitTesting(false)
    }

    private enum Metrics {
        static let photoFadeHeight: CGFloat = 150
        static let photoFadeEndBelowTitle: CGFloat = 32
    }
}
