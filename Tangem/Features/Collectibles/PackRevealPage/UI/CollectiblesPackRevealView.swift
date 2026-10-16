//
//  CollectiblesPackRevealView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct CollectiblesPackRevealView: View {
    @ObservedObject var viewModel: CollectiblesPackRevealViewModel

    let onKeep: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var isCardShown = false
    @State private var cardScale = Motion.cardStartScale
    @State private var cardLift = Motion.cardStartLift
    @State private var cardRotation: Double = 0
    @State private var cardOpacity: Double = 0
    @State private var isSettling = false
    @State private var isChromeShown = false
    @State private var isSkipped = false
    @State private var isLanded = false
    @State private var screenFrame: CGRect = .zero
    @State private var cardRegion: CardLayout.Region?

    var body: some View {
        let layout = CardLayout(region: cardRegion, screenFrame: screenFrame)

        return VStack(spacing: 0) {
            Color.clear
                .frame(height: Metrics.navigationBarTopPadding + Metrics.navigationBarHeight)

            Color.clear
                .infinityFrame()
                .readGeometry(\.frame, inCoordinateSpace: .global) { frame in
                    cardRegion = CardLayout.Region(top: frame.minY, detailsBaseline: frame.maxY + layout.detailsGap)
                }

            details
                .offset(y: chromeOffset)
                .animation(Motion.chromeRise, value: isChromeShown)
                .opacity(isChromeShown ? 1 : 0)
                .animation(Motion.chromeFade, value: isChromeShown)
                .allowsHitTesting(isChromeShown)
                .padding(.bottom, layout.detailsGap)

            footer
                .offset(y: chromeOffset)
                .animation(Motion.chromeRise, value: isChromeShown)
                .opacity(isChromeShown ? 1 : 0)
                .animation(Motion.chromeFade, value: isChromeShown)
                .allowsHitTesting(isChromeShown)
        }
        .background {
            background(layout: layout)
                .ignoresSafeArea()
        }
        .task(reveal)
    }
}

// MARK: - Content

private extension CollectiblesPackRevealView {
    // MARK: - View properties

    func background(layout: CardLayout) -> some View {
        GeometryReader { proxy in
            ZStack {
                video
                    .opacity(isSettling ? 0 : 1)

                if isCardShown {
                    stage(in: proxy.size, layout: layout)
                }
            }
            .readGeometry(\.frame, inCoordinateSpace: .global) { screenFrame = $0 }
        }
        .background(DesignSystem.Color.bgPrimary)
    }

    @ViewBuilder
    var video: some View {
        if let videoPlayer = viewModel.videoPlayer {
            CollectiblesPackRevealVideoView(player: videoPlayer)
                .contentShape(Rectangle())
                .onTapGesture(perform: viewModel.skip)
                .accessibilityElement()
                .accessibilityLabel(Localization.commonSkip)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { viewModel.skip() }
                .accessibilityHidden(isCardShown)
        }
    }

    var chromeOffset: CGFloat {
        isChromeShown || reduceMotion ? 0 : Motion.chromeRiseOffset
    }

    var timing: Motion.Timing {
        isSkipped ? .skipped : .regular
    }

    func stage(in size: CGSize, layout: CardLayout) -> some View {
        let cardHeight = layout.cardHeight ?? Metrics.cardHeight
        let cardWidth = cardHeight * Metrics.cardAspect
        let cardCenterY = layout.cardCenterY ?? size.height * Motion.cardCenterOfScreenHeight
        let cardCenter = CGPoint(x: size.width / 2, y: cardCenterY)

        return ZStack {
            cardFrame(cardSize: CGSize(width: cardWidth, height: cardHeight))
                .position(cardCenter)

            SpinningCard(
                rotation: cardRotation,
                imageURL: viewModel.prize.imageURL,
                backImageURL: viewModel.prize.backImageURL,
                cornerRadius: cardWidth * Motion.cardCornerRadiusOfWidth,
                perspectiveDistance: size.width * Motion.perspectiveOfScreenWidth
            )
            .frame(width: cardWidth, height: cardHeight)
            .opacity(cardOpacity)
            .scaleEffect(cardScale)
            .offset(y: cardLift * cardHeight)
            .contentShape(Rectangle())
            .onTapGesture(perform: flipOnTap)
            .position(cardCenter)
        }
    }

    func cardFrame(cardSize: CGSize) -> some View {
        Color.clear
            .tangemMaterialSurface(in: RoundedRectangle(cornerRadius: Metrics.frameCornerRadius, style: .continuous))
            .frame(width: cardSize.width + Metrics.frameInset * 2, height: cardSize.height + Metrics.frameInset * 2)
            .glowRing(
                viewModel.prize.glow ?? .magic,
                size: .card(cornerRadius: Metrics.frameCornerRadius),
                isVisible: isSettling && viewModel.prize.glow != nil
            )
            .scaleEffect(isSettling ? 1 : Motion.frameStartScale)
            .opacity(isSettling ? 1 : 0)
            .animation(Motion.settle(timing), value: isSettling)
    }

    var details: some View {
        VStack(spacing: Metrics.detailsSpacing) {
            if let rarityTitle = viewModel.prize.rarityTitle {
                Badge(label: rarityTitle, accessibilityLabel: nil)
                    .appearance(viewModel.prize.badgeAppearance)
                    .slotStart(DesignSystem.Icons.Dot.filled12)
            }

            VStack(spacing: Metrics.titleSpacing) {
                (
                    Text(viewModel.prize.name).foregroundColor(DesignSystem.Color.textPrimary)
                        + Text(" \(viewModel.prize.number)").foregroundColor(DesignSystem.Color.textSecondary)
                )
                .font(token: DesignSystem.Font.headingMediumToken)
                .multilineTextAlignment(.center)

                Text(viewModel.prize.subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .padding(.horizontal, Metrics.titleHorizontalPadding)
        }
    }

    var footer: some View {
        VStack(spacing: Metrics.buttonsSpacing) {
            TangemUI.Button(label: viewModel.prize.keepTitle, accessibilityLabel: nil, action: onKeep)
                .styleType(.secondary(.default))
                .horizontalLayout(.infinity)
                .size(.x12)

            TangemUI.Button(label: viewModel.prize.sellBackTitle, accessibilityLabel: nil, action: viewModel.sellBack)
                .styleType(.primary)
                .iconEnd(DesignSystem.Icons.LogoTangem.regular24)
                .horizontalLayout(.infinity)
                .size(.x12)
        }
        .padding(.horizontal, Metrics.horizontalPadding)
        .bottomPaddingIfZeroSafeArea()
        .padding(.top, Metrics.buttonsTopPadding)
    }
}

// MARK: - Reveal

private extension CollectiblesPackRevealView {
    func reveal() async {
        let result: CollectiblesRevealPlayerResult

        do {
            result = try await viewModel.playVideo(for: colorScheme)
        } catch {
            return
        }

        isSkipped = result.isSkipped
        isCardShown = true
        isChromeShown = true

        let timing = timing

        guard !reduceMotion else {
            cardScale = 1
            cardLift = 0
            withAnimation(Motion.appear(timing)) { cardOpacity = 1 }
            isSettling = true
            isLanded = true
            return
        }

        withAnimation(Motion.appear(timing)) { cardOpacity = 1 }
        withAnimation(Motion.spin(timing)) { cardRotation = 360 }
        withAnimation(Motion.rise(timing)) {
            cardScale = Motion.cardPeakScale
            cardLift = Motion.cardPeakLift
        }

        do {
            try await Task.sleep(for: .seconds(timing.rise))
        } catch {
            return
        }

        isSettling = true

        withAnimation(Motion.settle(timing)) {
            cardScale = 1
            cardLift = 0
        }

        do {
            try await Task.sleep(for: .seconds(timing.landing))
        } catch {
            return
        }

        isLanded = true
    }

    func flipOnTap() {
        guard isLanded, !reduceMotion else { return }

        withAnimation(Motion.tapFlip) { cardRotation += 180 }
    }
}

// MARK: - Metrics

private extension CollectiblesPackRevealView {
    enum Metrics {
        static let cardHeight: CGFloat = 406
        static let cardAspect: CGFloat = 260 / 406
        static let frameInset: CGFloat = 10
        static let frameCornerRadius: CGFloat = 20
        static let frameTopSpacing: CGFloat = 24
        static let frameToBadgeSpacing: CGFloat = 44
        static let detailsBottomSpacing: CGFloat = 24
        static let detailsSpacing: CGFloat = 12
        static let titleSpacing: CGFloat = 4
        static let horizontalPadding: CGFloat = 16
        static let titleHorizontalPadding: CGFloat = 24
        static let navigationBarTopPadding: CGFloat = 8
        static let navigationBarHeight: CGFloat = 56
        static let buttonsSpacing: CGFloat = 8
        static let buttonsTopPadding: CGFloat = 8
        static let compactSpacing: CGFloat = 24
        static let minimumSpacing: CGFloat = 16
        static let minimumTopSpacing: CGFloat = 8
    }
}

// MARK: - Card layout

private extension CollectiblesPackRevealView {
    struct CardLayout {
        struct Region: Equatable {
            let top, detailsBaseline: CGFloat
        }

        let cardHeight, cardCenterY: CGFloat?
        let detailsGap: CGFloat

        init(region: Region?, screenFrame: CGRect) {
            guard let region, screenFrame.width > 0 else {
                cardHeight = nil
                cardCenterY = nil
                detailsGap = Metrics.detailsBottomSpacing
                return
            }

            let frameInsets = Metrics.frameInset * 2
            let navigationBarBottom = region.top - screenFrame.minY
            let detailsBaseline = region.detailsBaseline - screenFrame.minY
            let availableHeight = detailsBaseline - navigationBarBottom

            var height = Metrics.cardHeight
            var topSpacing = Metrics.frameTopSpacing
            var badgeSpacing = Metrics.frameToBadgeSpacing
            var gap = Metrics.detailsBottomSpacing
            var excess = topSpacing + height + frameInsets + badgeSpacing + gap - availableHeight

            func reduce(_ value: inout CGFloat, downTo minimum: CGFloat) {
                let cut = min(max(0, excess), max(0, value - minimum))
                value -= cut
                excess -= cut
            }

            reduce(&badgeSpacing, downTo: Metrics.compactSpacing)
            reduce(&topSpacing, downTo: Metrics.minimumSpacing)
            reduce(&gap, downTo: Metrics.minimumSpacing)
            reduce(&badgeSpacing, downTo: Metrics.minimumSpacing)
            reduce(&topSpacing, downTo: Metrics.minimumTopSpacing)
            height = max(0, height - max(0, excess))

            let extraSpace = max(0, -excess)
            let frameTop = navigationBarBottom + topSpacing + extraSpace / 2
            let centerY = frameTop + (height + frameInsets) / 2

            cardHeight = height
            cardCenterY = centerY
            detailsGap = gap
        }
    }
}
