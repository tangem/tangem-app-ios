//
//  DeeplinkParser.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Every link that asks the app to open a screen, in both forms it arrives in: `tangem://<host>` and a page
/// on our domain. Which destination a link names and what it needs to carry is the action's own business, so
/// there is nothing to decide here.
struct DeeplinkParser: IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction? {
        DeeplinkURL(url: url)
            .flatMap(DeeplinkNavigationAction.init(link:))
            .map(IncomingAction.navigation)
    }
}
