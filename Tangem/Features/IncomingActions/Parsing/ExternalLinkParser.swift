//
//  ExternalLinkParser.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A page on our domain that no other parser claimed is just that — a page, to be opened in the in-app
/// browser. Being the last word on every link of ours, it runs after everything else: `IncomingActionParser`
/// keeps it out of the ordered list so it can't be moved in front of a parser that owns a page.
struct ExternalLinkParser: IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction? {
        // The attribution domain has no page of its own to show, and what it forwards to is a redirect that
        // would send the user back out of the app.
        guard case .path(let domain, _)? = DeeplinkURL(url: url)?.kind,
              domain != IncomingActionConstants.attributionHost else {
            return nil
        }

        return .externalLink(url)
    }
}
