//
//  OnrampIncomingActionURLParser.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct OnrampIncomingActionURLParser: IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction? {
        if url.absoluteString.starts(with: Constants.link) {
            return .dismissSafari(url)
        }

        return nil
    }
}

extension OnrampIncomingActionURLParser {
    enum Constants {
        static let link = "\(IncomingActionConstants.universalLinkScheme)onramp"
    }
}
