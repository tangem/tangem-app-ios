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

    public var id: TangemStory.ID {
        switch self {
        case .swap: .swap
        case .yieldFirstActivationAPYBoost: .yieldFirstActivationAPYBoost
        }
    }

    public var pagesCount: Int {
        pages.count
    }

    public var pages: [TangemStory.Page] {
        switch self {
        case .swap(let data): return data.pages
        case .yieldFirstActivationAPYBoost(let data): return data.pages
        }
    }

    /// When `true`, the story is shown on every entry and is not marked as viewed in persistent storage.
    public var isRepeatable: Bool {
        switch self {
        case .swap: false
        case .yieldFirstActivationAPYBoost: true
        }
    }
}

public extension TangemStory {
    enum ID: String, CaseIterable {
        case swap
        case yieldFirstActivationAPYBoost
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
