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
import TangemFoundation

public enum TangemStory: Identifiable {
    case swap(SwapStoryData)

    public var id: TangemStory.ID {
        switch self {
        case .swap: .swap
        }
    }

    public var pagesCount: Int {
        switch self {
        case .swap: 5
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

// MARK: - Swap story

public extension TangemStory {
    /// do not forget to update SwapStoryData.Property enum if you add / remove pages
    struct SwapStoryData {
        public var firstPage: Page
        public var secondPage: Page
        public var thirdPage: Page
        public var fourthPage: Page
        public var fifthPage: Page

        public static let initialWithoutImages = SwapStoryData(
            firstPage: Page(title: Localization.swapStoryFirstTitle, subtitle: Localization.swapStoryFirstSubtitle),
            secondPage: Page(title: Localization.swapStorySecondTitle, subtitle: Localization.swapStorySecondSubtitle),
            thirdPage: Page(title: Localization.swapStoryThirdTitle, subtitle: Localization.swapStoryThirdSubtitle),
            fourthPage: Page(title: Localization.swapStoryForthTitle, subtitle: Localization.swapStoryForthSubtitle),
            fifthPage: Page(title: Localization.swapStoryFifthTitle, subtitle: Localization.swapStoryFifthSubtitle)
        )
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
        case fifthPage

        var keyPath: WritableKeyPath<TangemStory.SwapStoryData, Page> {
            switch self {
            case .firstPage: \.firstPage
            case .secondPage: \.secondPage
            case .thirdPage: \.thirdPage
            case .fourthPage: \.fourthPage
            case .fifthPage: \.fifthPage
            }
        }
    }

    var pagesKeyPaths: [WritableKeyPath<TangemStory.SwapStoryData, Page>] {
        Property.allCases.map(\.keyPath)
    }
}
