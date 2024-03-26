//
//  BlockchainURLSchemesParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Parser for custom blockchains URL schemes, e.g. bitcoin:, doge: etc.
/// current implementation just chekcs that url scheme is supported,
/// actual parsing may be implemented in the future
struct BlockchainURLSchemesParser: IncomingActionURLParser {
    let isURLSchemeSupported: (URL) -> Bool

    func parse(_ url: URL) -> IncomingAction? {
        guard !url.absoluteString.starts(with: IncomingActionConstants.universalLinkScheme),
              isURLSchemeSupported(url) else {
            return nil
        }

        return .start
    }
}
