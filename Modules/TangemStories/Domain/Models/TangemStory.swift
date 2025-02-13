//
//  TangemStory.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct Foundation.URL

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
    enum ID: String {
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
    struct SwapStoryData {
        public var firstPage: Page
        public var secondPage: Page
        public var thirdPage: Page
        public var fourthPage: Page
        public var fifthPage: Page

        public init(firstPage: Page, secondPage: Page, thirdPage: Page, fourthPage: Page, fifthPage: Page) {
            self.firstPage = firstPage
            self.secondPage = secondPage
            self.thirdPage = thirdPage
            self.fourthPage = fourthPage
            self.fifthPage = fifthPage
        }
    }
}

public extension TangemStory.SwapStoryData {
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
