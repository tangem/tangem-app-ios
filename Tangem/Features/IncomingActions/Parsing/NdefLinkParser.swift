//
//  NdefLinkParser.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The link written on a card: tapping the card opens a page of ours with `ndef` in the path, which means
/// «scan», not «open a page». It runs after the destinations, so a page that names one — an article, an
/// invite — is still that page even with `ndef` somewhere further along its path.
struct NdefLinkParser: IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction? {
        guard
            case .path(_, let components)? = DeeplinkURL(url: url)?.kind,
            components.contains(IncomingActionConstants.ndefPath)
        else {
            return nil
        }

        return .start
    }
}
