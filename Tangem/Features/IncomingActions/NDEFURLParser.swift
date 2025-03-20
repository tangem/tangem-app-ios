//
//  NDEFURLParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct NDEFURLParser: IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction? {
        if url.absoluteString.starts(with: IncomingActionConstants.ndefURL) {
            return .start
        }

        return nil
    }
}
