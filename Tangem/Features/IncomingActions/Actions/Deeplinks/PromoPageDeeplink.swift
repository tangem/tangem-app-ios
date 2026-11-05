//
//  PromoPageDeeplink.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PromoPageDeeplink: HostNamedDeeplink, Equatable {
    static let host = "promo_page"

    let page: String?

    var action: DeeplinkNavigationAction { .promoPage(self) }
}

// MARK: - Parsing

extension PromoPageDeeplink {
    private enum Keys {
        static let page = "page"
    }

    init(link: DeeplinkURL) {
        page = link.query.decodedOnce(Keys.page)
    }
}
