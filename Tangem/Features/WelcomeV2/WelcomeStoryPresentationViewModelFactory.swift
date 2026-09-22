//
//  WelcomeStoryPresentationViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization
import TangemStories

@MainActor
struct WelcomeStoryPresentationViewModelFactory {
    @Injected(\.storiesAnalyticsProvider) private var analyticsProvider: any StoriesAnalyticsProvider

    /// Screen keys the welcome coordinator routes story exits by.
    enum ScreenKey {
        static let hardwareWallet = "hardware_wallet"
    }

    enum ActionID {
        static let learnMore = "welcome_story_learn_more"
        static let scanWallet = "welcome_story_scan_wallet"
    }

    enum StoryConstants {
        static let storyID = "welcome_onboarding"
        static let placement = "onboarding"
        /// Playback follows the real media length; this is the contract value the story reports,
        /// so it has to be re-checked against the bundled clips whenever they are replaced.
        static let slideDurationMs = 7000
    }

    func make(
        provider: WelcomeStoryProviding,
        onAction: @escaping (StoryActionV2) -> Void,
        onFinished: @escaping (StoryExitReason, StoryActionV2?) -> Void
    ) -> WelcomeStoryPresentationViewModel? {
        let urls = provider.welcomeStoryVideoURLs()
        // A missing bundled video would shift the zip and misalign copy with footage —
        // an incomplete asset set falls back to the hardware screen instead.
        guard urls.count == slideCopy.count else { return nil }

        let story = StoryV2(
            id: StoryConstants.storyID,
            placements: [StoryConstants.placement],
            displayPolicy: .always,
            endBehavior: .loop,
            actions: makeActions(),
            slides: makeSlides(urls: urls),
            origin: .bundled
        )

        let player = StoryPlayerViewModel(
            story: story,
            source: .onboarding,
            analytics: analyticsProvider,
            hapticPlayer: CommonStoryHapticPlayer(),
            onAction: onAction,
            onFinished: onFinished
        )
        return WelcomeStoryPresentationViewModel(player: player, scanAction: scanAction)
    }

    private func makeActions() -> [StoryActionV2] {
        [
            StoryActionV2(
                id: ActionID.learnMore,
                label: Localization.introductionStoriesButtonSecondary,
                style: .secondary,
                target: .web(TangemShopUrlBuilder().url(utmCampaign: .prospect).absoluteString)
            ),
            scanAction,
        ]
    }

    private var scanAction: StoryActionV2 {
        StoryActionV2(
            id: ActionID.scanWallet,
            label: Localization.introductionStoriesButtonPrimary,
            style: .primary,
            target: .screen(ScreenKey.hardwareWallet),
            icon: Assets.tangemIcon
        )
    }

    /// Haptic timings were authored against these exact clips in the onboarding prototype, so
    /// they have to be re-checked whenever the footage is replaced.
    private let slideCopy: [SlideCopy] = [
        SlideCopy(
            title: Localization.introductionStoriesOneTitle,
            subtitle: Localization.introductionStoriesOneSubtitle,
            hapticAtMs: [600, 1050, 1450, 1560]
        ),
        SlideCopy(
            title: Localization.introductionStoriesTwoTitle,
            subtitle: Localization.introductionStoriesTwoSubtitle,
            hapticAtMs: [4700]
        ),
        SlideCopy(
            title: Localization.introductionStoriesThreeTitle,
            subtitle: Localization.introductionStoriesThreeSubtitle,
            hapticAtMs: (0 ..< 12).map { 350 + $0 * 30 }
        ),
        SlideCopy(
            title: Localization.introductionStoriesFourTitle,
            subtitle: Localization.introductionStoriesFourSubtitle,
            hapticAtMs: (0 ..< 8).map { 250 + $0 * 30 } + [1500]
        ),
    ]

    private func makeSlides(urls: [URL]) -> [SlideV2] {
        zip(urls, slideCopy).enumerated().map { index, pair in
            let order = index + 1
            let (url, copy) = pair
            return SlideV2(
                id: "welcome_slide_\(order)",
                order: order,
                title: copy.title,
                subtitle: copy.subtitle,
                asset: AssetV2(type: .video, contentMode: .cover, durationMs: StoryConstants.slideDurationMs, url: url),
                hapticAtMs: copy.hapticAtMs
            )
        }
    }

    private struct SlideCopy {
        let title: String
        let subtitle: String
        let hapticAtMs: [Int]
    }
}
