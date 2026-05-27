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
    case swapLegacy(SwapStoryDataLegacy)

    public var id: TangemStory.ID {
        switch self {
        case .swap, .swapLegacy: .swap
        }
    }

    public var pagesCount: Int {
        switch self {
        case .swap: 4
        case .swapLegacy: 5
        }
    }
}

public extension TangemStory {
    enum ID: String, CaseIterable {
        case swap
    }

    struct Image {
        public var url: URL
        public var rawData: Data

        public init(url: URL, rawData: Data) {
            self.url = url
            self.rawData = rawData
        }
    }
}

// MARK: - Swap story pages container

public protocol SwapStoryDataPagesContainer {
    var pagesKeyPaths: [WritableKeyPath<Self, TangemStory.SwapStoryData.Page>] { get }
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

extension TangemStory.SwapStoryData: SwapStoryDataPagesContainer {
    public var pagesKeyPaths: [WritableKeyPath<TangemStory.SwapStoryData, Page>] {
        Property.allCases.map(\.keyPath)
    }
}

public extension TangemStory.SwapStoryData {
    struct Page {
        public let title: String
        public let subtitle: String
        public var image: TangemStory.Image?
    }

    enum Property: CaseIterable {
        case firstPage
        case secondPage
        case thirdPage
        case fourthPage

        var keyPath: WritableKeyPath<TangemStory.SwapStoryData, Page> {
            switch self {
            case .firstPage: \.firstPage
            case .secondPage: \.secondPage
            case .thirdPage: \.thirdPage
            case .fourthPage: \.fourthPage
            }
        }
    }
}

// MARK: - Swap story (legacy)

public extension TangemStory {
    /// do not forget to update SwapStoryDataLegacy.Property enum if you add / remove pages
    struct SwapStoryDataLegacy {
        public var firstPage: Page
        public var secondPage: Page
        public var thirdPage: Page
        public var fourthPage: Page
        public var fifthPage: Page

        public static let initialWithoutImages = SwapStoryDataLegacy(
            firstPage: Page(title: Localization.swapStoryFirstTitle, subtitle: Localization.swapStoryFirstSubtitle),
            secondPage: Page(title: Localization.swapStorySecondTitle, subtitle: Localization.swapStorySecondSubtitle),
            thirdPage: Page(title: Localization.swapStoryThirdTitle, subtitle: Localization.swapStoryThirdSubtitle),
            fourthPage: Page(title: Localization.swapStoryForthTitle, subtitle: Localization.swapStoryForthSubtitle),
            fifthPage: Page(title: Localization.swapStoryFifthTitle, subtitle: Localization.swapStoryFifthSubtitle)
        )
    }
}

extension TangemStory.SwapStoryDataLegacy: SwapStoryDataPagesContainer {
    public var pagesKeyPaths: [WritableKeyPath<TangemStory.SwapStoryDataLegacy, Page>] {
        Property.allCases.map(\.keyPath)
    }
}

public extension TangemStory.SwapStoryDataLegacy {
    typealias Page = TangemStory.SwapStoryData.Page

    enum Property: CaseIterable {
        case firstPage
        case secondPage
        case thirdPage
        case fourthPage
        case fifthPage

        var keyPath: WritableKeyPath<TangemStory.SwapStoryDataLegacy, Page> {
            switch self {
            case .firstPage: \.firstPage
            case .secondPage: \.secondPage
            case .thirdPage: \.thirdPage
            case .fourthPage: \.fourthPage
            case .fifthPage: \.fifthPage
            }
        }
    }
}
