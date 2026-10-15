//
//  CollectiblesPackRevealView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Kingfisher
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct CollectiblesPackRevealView: View {
    @ObservedObject var viewModel: CollectiblesPackRevealViewModel

    let onBack: () -> Void
    let onKeep: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var videoPlayer: AVPlayer?
    @State private var isCardShown = false
    @State private var cardScale = Motion.cardStartScale
    @State private var cardLift = Motion.cardStartLift
    @State private var cardRotation: Double = 0
    @State private var whiteOverlayOpacity: Double = 1
    @State private var isLanded = false

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .opacity(isLanded ? 1 : 0)
                .allowsHitTesting(isLanded)
                .animation(Motion.detailsAppearance, value: isLanded)

            Spacer()

            details
                .offset(y: detailsOffset)
                .opacity(isLanded ? 1 : 0)
                .animation(Motion.detailsAppearance, value: isLanded)
                .padding(.bottom, Metrics.detailsBottomSpacing)

            footer
                .offset(y: detailsOffset)
                .opacity(isLanded ? 1 : 0)
                .allowsHitTesting(isLanded)
                .animation(Motion.detailsAppearance, value: isLanded)
        }
        .background {
            GeometryReader { proxy in
                ZStack {
                    video
                        .opacity(isLanded ? 0 : 1)
                        .animation(Motion.detailsAppearance, value: isLanded)

                    if isCardShown {
                        stage(in: proxy.size)

                        Color.white
                            .opacity(whiteOverlayOpacity)
                            .allowsHitTesting(false)
                    }
                }
            }
            .background(DesignSystem.Color.bgPrimary)
            .ignoresSafeArea()
        }
        .background(PopGestureDisabler(isDisabled: !isLanded))
        .task(reveal)
    }
}

// MARK: - Content

private extension CollectiblesPackRevealView {
    // MARK: - View properties

    @ViewBuilder
    var video: some View {
        if let videoPlayer {
            CollectiblesPackRevealVideoView(player: videoPlayer)
        }
    }

    var detailsOffset: CGFloat {
        isLanded || reduceMotion ? 0 : Motion.detailsOffset
    }

    func stage(in size: CGSize) -> some View {
        let cardWidth = size.width * Motion.cardWidthOfScreen
        let cardHeight = cardWidth / Motion.cardAspect
        let cardCenter = CGPoint(x: size.width / 2, y: size.height * Motion.cardCenterOfScreenHeight)

        return ZStack {
            cardFrame(cardSize: CGSize(width: cardWidth, height: cardHeight))
                .position(x: cardCenter.x, y: cardCenter.y - Metrics.frameCenterShift)

            SpinningCard(
                rotation: cardRotation,
                imageURL: viewModel.prize.imageURL,
                cornerRadius: cardWidth * Motion.cardCornerRadiusOfWidth,
                perspectiveDistance: size.width * Motion.perspectiveOfScreenWidth
            )
            .frame(width: cardWidth, height: cardHeight)
            .scaleEffect(cardScale)
            .offset(y: cardLift * cardHeight)
            .contentShape(Rectangle())
            .onTapGesture(perform: spinOnTap)
            .position(cardCenter)
        }
    }

    func cardFrame(cardSize: CGSize) -> some View {
        Color.clear
            .tangemMaterialSurface(in: RoundedRectangle(cornerRadius: Metrics.frameCornerRadius, style: .continuous))
            .overlay(alignment: .top) { gradeRow }
            .frame(
                width: cardSize.width + Metrics.frameHorizontalInset * 2,
                height: cardSize.height + Metrics.frameTopInset + Metrics.frameBottomInset
            )
            .glowRing(viewModel.prize.glow, size: .card(cornerRadius: Metrics.frameCornerRadius), isVisible: isLanded)
            .opacity(isLanded ? 1 : 0)
            .animation(Motion.detailsAppearance, value: isLanded)
    }

    var gradeRow: some View {
        HStack {
            Text(viewModel.prize.gradeText)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            Spacer()

            Text(viewModel.prize.serialText)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
        }
        .padding(.horizontal, Metrics.gradeRowHorizontalPadding)
        .frame(height: Metrics.frameTopInset)
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
            .padding(.horizontal, Metrics.horizontalPadding)
        }
    }

    var navigationBar: some View {
        NavigationBar(
            settings: .init(
                backgroundColor: .clear,
                horizontalPadding: Metrics.horizontalPadding,
                height: Metrics.navigationBarHeight
            ),
            titleView: EmptyView.init,
            leftButtons: { NavigationBarButton.back(action: onBack) },
            rightButtons: EmptyView.init
        )
        .padding(.top, Metrics.navigationBarTopPadding)
        .environment(\.isRedesign, true)
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
        .padding(.top, Metrics.buttonsTopPadding)
    }
}

// MARK: - Reveal

private extension CollectiblesPackRevealView {
    func reveal() async {
        if let imageURL = viewModel.prize.imageURL {
            ImagePrefetcher(urls: [imageURL]).start()
        }

        if let videoURL = viewModel.videoURL {
            let player = AVPlayer(url: videoURL)
            AmbientAudioSession.configure()
            videoPlayer = player
            player.play()

            do {
                try await waitForFlash(of: player)
            } catch {
                return
            }
        }

        isCardShown = true

        guard !reduceMotion else {
            cardScale = 1
            cardLift = 0
            withAnimation(Motion.whiteOverlayFade) { whiteOverlayOpacity = 0 }
            isLanded = true
            return
        }

        withAnimation(Motion.whiteOverlayFade) { whiteOverlayOpacity = 0 }
        withAnimation(Motion.spin) { cardRotation = 360 }
        withAnimation(Motion.rise) {
            cardScale = Motion.cardPeakScale
            cardLift = Motion.cardPeakLift
        }

        do {
            try await Task.sleep(for: Motion.riseDuration)
        } catch {
            return
        }

        withAnimation(Motion.settle) {
            cardScale = 1
            cardLift = 0
        }

        do {
            try await Task.sleep(for: Motion.landingTime)
        } catch {
            return
        }

        isLanded = true
    }

    func waitForFlash(of player: AVPlayer) async throws {
        var lastTime = player.currentTime().seconds
        var lastProgress = ContinuousClock.now

        while player.currentTime().seconds < flashTime(of: player), player.currentItem?.status != .failed {
            try await Task.sleep(for: Motion.videoPollInterval)

            let time = player.currentTime().seconds

            if time != lastTime || UIApplication.shared.applicationState != .active {
                lastTime = time
                lastProgress = .now
            } else if ContinuousClock.now - lastProgress >= Motion.videoStallTimeout {
                return
            }
        }
    }

    func flashTime(of player: AVPlayer) -> Double {
        guard let duration = player.currentItem?.duration.seconds, duration.isFinite else {
            return Motion.videoFlashTime
        }

        return min(Motion.videoFlashTime, duration - Motion.videoEndTolerance)
    }

    func spinOnTap() {
        guard isLanded, !reduceMotion else { return }

        withAnimation(Motion.tapSpin) { cardRotation += 360 }
    }
}

// MARK: - Metrics

private extension CollectiblesPackRevealView {
    enum Metrics {
        static let frameHorizontalInset: CGFloat = 10
        static let frameTopInset: CGFloat = 38
        static let frameBottomInset: CGFloat = 10
        static let frameCenterShift: CGFloat = (frameTopInset - frameBottomInset) / 2
        static let frameCornerRadius: CGFloat = 20
        static let gradeRowHorizontalPadding: CGFloat = 20
        static let detailsBottomSpacing: CGFloat = 60
        static let detailsSpacing: CGFloat = 12
        static let titleSpacing: CGFloat = 4
        static let horizontalPadding: CGFloat = 16
        static let navigationBarTopPadding: CGFloat = 8
        static let navigationBarHeight: CGFloat = 56
        static let buttonsSpacing: CGFloat = 8
        static let buttonsTopPadding: CGFloat = 8
    }
}
