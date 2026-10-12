//
//  TangemStory.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct Foundation.URL
import enum TangemLocalization.Localization

public enum TangemStory: Identifiable {
    case swap(SwapStoryData)
    case yieldFirstActivationAPYBoost(YieldFirstActivationAPYBoostStoryData)
    case polymarketOnboarding(PolymarketOnboardingStoryData)

    public var id: TangemStory.ID {
        switch self {
        case .swap: .swap
        case .yieldFirstActivationAPYBoost: .yieldFirstActivationAPYBoost
        case .polymarketOnboarding: .polymarketOnboarding
        }
    }

    /// Only the artwork that is drawn to the very bottom of the page needs the home-indicator strip;
    /// the rest keep their captions above it.
    public var runsArtToTheBottomEdge: Bool {
        switch self {
        case .polymarketOnboarding: true
        case .swap, .yieldFirstActivationAPYBoost: false
        }
    }

    public var pagesCount: Int {
        pages.count
    }

    public var pages: [TangemStory.Page] {
        switch self {
        case .swap(let data): return data.pages
        case .yieldFirstActivationAPYBoost(let data): return data.pages
        case .polymarketOnboarding(let data): return data.pages
        }
    }

    /// When `true`, the story is shown on every entry and is not marked as viewed in persistent storage.
    public var isRepeatable: Bool {
        switch self {
        case .swap: false
        case .yieldFirstActivationAPYBoost: true
        case .polymarketOnboarding: false
        }
    }
}

public extension TangemStory {
    enum ID: String, CaseIterable {
        case swap
        case yieldFirstActivationAPYBoost
        case polymarketOnboarding
    }

    struct Image {
        public var url: URL
        public var rawData: Data

        public init(url: URL, rawData: Data) {
            self.url = url
            self.rawData = rawData
        }
    }

    struct Page {
        public let title: String
        public let subtitle: String
        public var image: TangemStory.Image?

        public init(title: String, subtitle: String, image: TangemStory.Image? = nil) {
            self.title = title
            self.subtitle = subtitle
            self.image = image
        }
    }
}

// MARK: - Story pages container

public protocol StoryPagesContainer {
    var pagesKeyPaths: [WritableKeyPath<Self, TangemStory.Page>] { get }
}

public extension StoryPagesContainer {
    var pages: [TangemStory.Page] {
        pagesKeyPaths.map { self[keyPath: $0] }
    }
}

// MARK: - Swap story

public extension TangemStory {
    /// do not forget to update SwapStoryData.Property enum if you add / remove pages
    struct SwapStoryData {
        public var firstPage: Page
        public var secondPage: Page
        public var thirdPage: Page
        public var fourthPage: Page

        public static let initialWithoutImages = SwapStoryData(
            firstPage: Page(title: Localization.swapStoryFirstTitleV2, subtitle: Localization.swapStoryFirstSubtitleV2),
            secondPage: Page(title: Localization.swapStorySecondTitleV2, subtitle: Localization.swapStorySecondSubtitleV2),
            thirdPage: Page(title: Localization.swapStoryThirdTitleV2, subtitle: Localization.swapStoryThirdSubtitleV2),
            fourthPage: Page(title: Localization.swapStoryForthTitleV2, subtitle: Localization.swapStoryForthSubtitleV2)
        )
    }
}

extension TangemStory.SwapStoryData: StoryPagesContainer {
    public var pagesKeyPaths: [WritableKeyPath<TangemStory.SwapStoryData, TangemStory.Page>] {
        Property.allCases.map(\.keyPath)
    }
}

public extension TangemStory.SwapStoryData {
    enum Property: CaseIterable {
        case firstPage
        case secondPage
        case thirdPage
        case fourthPage

        var keyPath: WritableKeyPath<TangemStory.SwapStoryData, TangemStory.Page> {
            switch self {
            case .firstPage: \.firstPage
            case .secondPage: \.secondPage
            case .thirdPage: \.thirdPage
            case .fourthPage: \.fourthPage
            }
        }
    }
}

// MARK: - Yield first activation APY boost story

public extension TangemStory {
    /// do not forget to update YieldFirstActivationAPYBoostStoryData.Property enum if you add / remove pages
    struct YieldFirstActivationAPYBoostStoryData {
        public var firstPage: Page
        public var secondPage: Page
        public var thirdPage: Page
        public var fourthPage: Page

        public static let initialWithoutImages = YieldFirstActivationAPYBoostStoryData(
            firstPage: Page(
                title: Localization.yieldApyBoostStoryFirstTitle,
                subtitle: Localization.yieldApyBoostStoryFirstSubtitle
            ),
            secondPage: Page(
                title: Localization.yieldApyBoostStorySecondTitle,
                subtitle: Localization.yieldApyBoostStorySecondSubtitle
            ),
            thirdPage: Page(
                title: Localization.yieldApyBoostStoryThirdTitle,
                subtitle: Localization.yieldApyBoostStoryThirdSubtitle
            ),
            fourthPage: Page(
                title: Localization.yieldApyBoostStoryFourthTitle,
                subtitle: Localization.yieldApyBoostStoryFourthSubtitle
            )
        )
    }
}

extension TangemStory.YieldFirstActivationAPYBoostStoryData: StoryPagesContainer {
    public var pagesKeyPaths: [WritableKeyPath<TangemStory.YieldFirstActivationAPYBoostStoryData, TangemStory.Page>] {
        Property.allCases.map(\.keyPath)
    }
}

public extension TangemStory.YieldFirstActivationAPYBoostStoryData {
    enum Property: CaseIterable {
        case firstPage
        case secondPage
        case thirdPage
        case fourthPage

        var keyPath: WritableKeyPath<TangemStory.YieldFirstActivationAPYBoostStoryData, TangemStory.Page> {
            switch self {
            case .firstPage: \.firstPage
            case .secondPage: \.secondPage
            case .thirdPage: \.thirdPage
            case .fourthPage: \.fourthPage
            }
        }
    }
}

// MARK: - Polymarket onboarding story

public extension TangemStory {
    /// Adding or removing a page here requires the same change in `Property`, which drives the page order.
    struct PolymarketOnboardingStoryData {
        public var firstPage: Page
        public var secondPage: Page
        public var thirdPage: Page
        public var fourthPage: Page

        // [REDACTED_TODO_COMMENT]
        public static let initialWithoutImages = PolymarketOnboardingStoryData(
            firstPage: Page(
                title: "How to read a prediction",
                subtitle: "An Event (like the FIFA World Cup) holds Markets — the possible outcomes (France to win, Brazil to win…). Each outcome has a price in cents, and that price is the crowd's odds: 65¢ ≈ a 65% chance."
            ),
            secondPage: Page(
                title: "Win = $1, lose = $0",
                subtitle: "Every share is a token tied to one outcome. When the event settles, winning shares are worth $1 each and losing shares $0. Your profit is the gap between what you paid and that final value."
            ),
            thirdPage: Page(
                title: "Built for live markets",
                subtitle: "During live events, prices move by the second. Tangem lets you set how much price movement you'll accept (slippage), so your order still goes through when the odds shift fast."
            ),
            fourthPage: Page(
                title: "Track it from your home screen",
                subtitle: "Open predictions appear right on your main screen. Even after an event settles, Tangem keeps the position there so you can tap to acknowledge your win or loss — nothing clears without you seeing it."
            )
        )
    }
}

extension TangemStory.PolymarketOnboardingStoryData: StoryPagesContainer {
    public var pagesKeyPaths: [WritableKeyPath<TangemStory.PolymarketOnboardingStoryData, TangemStory.Page>] {
        Property.allCases.map(\.keyPath)
    }
}

public extension TangemStory.PolymarketOnboardingStoryData {
    enum Property: CaseIterable {
        case firstPage
        case secondPage
        case thirdPage
        case fourthPage

        var keyPath: WritableKeyPath<TangemStory.PolymarketOnboardingStoryData, TangemStory.Page> {
            switch self {
            case .firstPage: \.firstPage
            case .secondPage: \.secondPage
            case .thirdPage: \.thirdPage
            case .fourthPage: \.fourthPage
            }
        }
    }
}
