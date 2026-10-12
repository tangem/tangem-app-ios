//
//  FeedDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// `tangem://discover[?section&category&type]`
public struct FeedDeeplink: HostNamedDeeplink, Equatable {
    /// The wire name of the link, shared with Android — which is why it is `discover` while everything the
    /// link opens is the feed.
    static let host = "discover"

    let section: String?
    let category: String?
    let type: String?

    var action: DeeplinkNavigationAction { .feed(self) }
}

// MARK: - Parsing

extension FeedDeeplink {
    private enum Keys {
        static let section = "section"
        static let category = "category"
        static let type = "type"
    }

    init(link: DeeplinkURL) {
        section = link.query.unchecked(Keys.section, lowercased: true)
        category = link.query.unchecked(Keys.category, lowercased: true)
        type = link.query.unchecked(Keys.type, lowercased: true)
    }
}

// MARK: - Navigation

extension FeedDeeplink {
    func makeSelection() -> FeedSelection {
        let categoryId = category?.nilIfEmpty

        switch section.flatMap(Section.init(rawValue:)) {
        case .assets:
            return .realAssets(categoryId: categoryId)
        case .earn:
            return .earn(type: type.flatMap(EarnFilterType.init(rawValue:)))
        case .crypto, .none:
            return .crypto(categoryId: categoryId)
        }
    }
}

// MARK: - Section

private extension FeedDeeplink {
    enum Section: String {
        case crypto
        case assets
        case earn
    }
}
