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
        AppLogger.info("[OnrampIncomingActionURLParser.parse] url=\(url.absoluteString) expectedPrefix=\(Constants.link)")
        if url.absoluteString.starts(with: Constants.link) {
            AppLogger.info("[OnrampIncomingActionURLParser.parse] matched -> .dismissSafari")
            return .dismissSafari(url)
        }

        AppLogger.info("[OnrampIncomingActionURLParser.parse] no match")
        return nil
    }
}

extension OnrampIncomingActionURLParser {
    enum Constants {
        static let link = "\(IncomingActionConstants.universalLinkScheme)onramp"
    }
}
